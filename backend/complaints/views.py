import os
from django.db.models import Count, Avg
from rest_framework import status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

from .models import Complaint, ComplaintCluster, MaintenanceCrew, ComplaintStatus
from .serializers import (
    ComplaintCreateSerializer,
    ComplaintDetailSerializer,
    ComplaintClusterSerializer,
    MaintenanceCrewSerializer,
    ComplaintConfirmSerializer,
    PriorityOverrideSerializer
)
from .services import (
    validate_image_clarity,
    detect_civic_defects,
    analyze_civic_issue,
    compress_image,
    cluster_and_weight_complaint,
    dispatch_cluster_to_crew,
    evaluate_submission_trust,
    adjust_user_trust_score
)

class HealthCheckView(APIView):
    """Health check endpoint for Docker containers and frontend connectivity."""
    def get(self, request):
        return Response({
            "status": "healthy",
            "service": "ACTS Autonomous Civic Triage System API",
            "version": "1.0.0"
        }, status=status.HTTP_200_OK)


class ComplaintCreateView(APIView):
    """
    Step 1 & 2: Citizen/Student reports an issue with plain-text & optional photo.
    Step 3: AI Triage + Crowd Clustering + Smart Crew Dispatch.
    """
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def post(self, request, *args, **kwargs):
        serializer = ComplaintCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        complaint = serializer.save()
        image_file = request.FILES.get('image')

        # 1. Computer Vision Pipeline (if photo provided)
        if image_file:
            is_clear, blur_score = validate_image_clarity(image_file)
            compressed_file = compress_image(image_file)
            complaint.is_valid_image = is_clear
            complaint.blur_score = blur_score
            complaint.compressed_image = compressed_file
            complaint.save()

            if complaint.image and hasattr(complaint.image, 'path') and os.path.exists(complaint.image.path):
                complaint.yolo_detections = detect_civic_defects(complaint.image.path)

        # 2. AI Triage Pipeline (Gemini Multimodal / Text)
        image_path = complaint.image.path if (complaint.image and hasattr(complaint.image, 'path') and os.path.exists(complaint.image.path)) else None
        gemini_result = analyze_civic_issue(raw_text=complaint.raw_text, image_path=image_path)
        
        complaint.gemini_analysis = gemini_result
        complaint.department = gemini_result.get('department', 'GENERAL')
        if "severity_score" in gemini_result and isinstance(gemini_result["severity_score"], (int, float)):
            complaint.initial_severity = int(gemini_result["severity_score"])

        # 3. Trust Evaluation
        initial_status = evaluate_submission_trust(complaint.user_trust_score)
        complaint.status = initial_status
        complaint.save()

        # 4. Crowd-Weighted Clustering (Duplicate Merging & Urgency Climbing)
        cluster, is_new = cluster_and_weight_complaint(complaint)

        # 5. Smart Routing Engine (Auto-dispatch nearest available crew)
        if not cluster.assigned_crew:
            dispatch_cluster_to_crew(cluster)

        detail_serializer = ComplaintDetailSerializer(complaint, context={'request': request})
        return Response({
            "message": "Complaint processed and merged into triage pipeline.",
            "is_new_cluster": is_new,
            "crowd_report_count": cluster.crowd_report_count,
            "computed_priority": cluster.computed_priority,
            "cluster_id": cluster.id,
            "complaint": detail_serializer.data
        }, status=status.HTTP_201_CREATED)


class ComplaintListView(generics.ListAPIView):
    """List citizen reports with filters for user_identifier, status, and campus_zone."""
    serializer_class = ComplaintDetailSerializer

    def get_queryset(self):
        queryset = Complaint.objects.all().select_related('cluster', 'assigned_crew')
        user_id = self.request.query_params.get('user_identifier')
        status_param = self.request.query_params.get('status')
        zone_param = self.request.query_params.get('campus_zone')

        if user_id:
            queryset = queryset.filter(user_identifier=user_id)
        if status_param:
            queryset = queryset.filter(status=status_param)
        if zone_param:
            queryset = queryset.filter(campus_zone=zone_param)

        return queryset


class ComplaintDetailView(generics.RetrieveAPIView):
    """Retrieve full details of an individual complaint report."""
    queryset = Complaint.objects.all().select_related('cluster', 'assigned_crew')
    serializer_class = ComplaintDetailSerializer
    lookup_field = 'id'


class ComplaintConfirmResolutionView(APIView):
    """
    Step 6: Reporter Confirmation
    Reporter confirms if fix was successful (Closes ticket + increases reputation)
    or rejects (Reopens ticket for crew reinspection).
    """
    def post(self, request, id):
        try:
            complaint = Complaint.objects.get(id=id)
        except Complaint.DoesNotExist:
            return Response({"error": "Complaint not found"}, status=status.HTTP_404_NOT_FOUND)

        serializer = ComplaintConfirmSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        is_confirmed = serializer.validated_data['is_confirmed']
        feedback = serializer.validated_data.get('feedback', '')

        complaint.is_confirmed_by_reporter = is_confirmed
        complaint.reporter_feedback = feedback

        if is_confirmed:
            complaint.status = ComplaintStatus.CLOSED
            if complaint.cluster:
                complaint.cluster.status = ComplaintStatus.CLOSED
                complaint.cluster.save()
            adjust_user_trust_score(complaint.user_identifier, is_accurate=True)
            msg = "Resolution confirmed by reporter. Ticket closed."
        else:
            complaint.status = ComplaintStatus.REOPENED
            if complaint.cluster:
                complaint.cluster.status = ComplaintStatus.REOPENED
                complaint.cluster.save()
            msg = "Reporter indicated fix did not hold. Ticket reopened."

        complaint.save()
        return Response({"message": msg, "status": complaint.status})


class AdminClusterListView(generics.ListAPIView):
    """Admin live feed of complaint clusters ordered by crowd priority."""
    serializer_class = ComplaintClusterSerializer

    def get_queryset(self):
        queryset = ComplaintCluster.objects.all().select_related('assigned_crew')
        status_param = self.request.query_params.get('status')
        if status_param:
            queryset = queryset.filter(status=status_param)
        return queryset


class AdminMapMarkersView(APIView):
    """
    Section 5.4: Live Command Center Map
    Returns open clusters with GPS, urgency color codes, crowd count, and assigned crew.
    """
    def get(self, request):
        clusters = ComplaintCluster.objects.exclude(
            status__in=[ComplaintStatus.CLOSED, ComplaintStatus.REJECTED]
        ).select_related('assigned_crew')

        data = []
        for c in clusters:
            data.append({
                "id": str(c.id),
                "title": c.title,
                "department": c.department,
                "campus_zone": c.campus_zone,
                "latitude": float(c.latitude),
                "longitude": float(c.longitude),
                "crowd_count": c.crowd_report_count,
                "computed_priority": c.computed_priority,
                "status": c.status,
                "assigned_crew_name": c.assigned_crew.name if c.assigned_crew else None,
                "created_at": c.created_at.isoformat()
            })

        return Response(data, status=status.HTTP_200_OK)


class CampusHealthAnalyticsView(APIView):
    """
    Section 5.4: Campus-wide Health View
    Aggregates issue frequency and average severity per building / campus zone.
    """
    def get(self, request):
        stats = Complaint.objects.values('campus_zone', 'department').annotate(
            total_issues=Count('id'),
            avg_severity=Avg('initial_severity')
        ).order_by('-total_issues')

        return Response({"campus_health": list(stats)}, status=status.HTTP_200_OK)


class PriorityOverrideView(APIView):
    """Section 5.4: Admin manual override of AI-assigned priority score."""
    def post(self, request, cluster_id):
        try:
            cluster = ComplaintCluster.objects.get(id=cluster_id)
        except ComplaintCluster.DoesNotExist:
            return Response({"error": "Cluster not found"}, status=status.HTTP_404_NOT_FOUND)

        serializer = PriorityOverrideSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        cluster.computed_priority = serializer.validated_data['priority']
        cluster.save()

        return Response({
            "message": f"Priority updated to {cluster.computed_priority}",
            "cluster_id": cluster.id,
            "new_priority": cluster.computed_priority
        })


class MaintenanceCrewListCreateView(generics.ListCreateAPIView):
    """Manage repair crews and view live locations/workload."""
    queryset = MaintenanceCrew.objects.all()
    serializer_class = MaintenanceCrewSerializer


class AdminConnectPortalView(APIView):
    """
    Section 5.5: Admin Connect Portal
    Returns designated contact / officer for a specific department or building.
    """
    def get(self, request):
        dept = request.query_params.get('department', 'GENERAL')
        contacts = {
            "PLUMBING": {"officer": "Mr. R. K. Sharma", "designation": "Superintendent of Water Works", "phone": "+91 98765 43210", "email": "plumbing@campus.edu"},
            "ELECTRICAL": {"officer": "Mr. A. Verma", "designation": "Chief Electrical Engineer", "phone": "+91 98765 43211", "email": "electrical@campus.edu"},
            "SANITATION": {"officer": "Mrs. S. Devi", "designation": "Sanitation Officer", "phone": "+91 98765 43212", "email": "sanitation@campus.edu"},
            "CIVIL": {"officer": "Mr. P. Gupta", "designation": "Campus Estate Manager", "phone": "+91 98765 43213", "email": "civil@campus.edu"},
            "SAFETY": {"officer": "Chief Proctor / Security Control", "designation": "Campus Safety Chief", "phone": "+91 98765 43214", "email": "safety@campus.edu"},
            "GENERAL": {"officer": "Central Maintenance Desk", "designation": "Helpdesk Coordinator", "phone": "+91 98765 43200", "email": "admin@campus.edu"},
        }
        return Response(contacts.get(dept.upper(), contacts["GENERAL"]))

import os
from rest_framework import status, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser

from .models import Complaint, ComplaintStatus
from .serializers import (
    ComplaintCreateSerializer,
    ComplaintDetailSerializer,
    ComplaintMapMarkerSerializer,
    ComplaintStatusUpdateSerializer
)
from .services import (
    validate_image_clarity,
    detect_civic_defects,
    analyze_civic_issue,
    compress_image
)

class ComplaintCreateView(APIView):
    """
    Endpoint for Citizens to submit a new complaint with photo & GPS location.
    Executes automated CV & AI pipeline:
    1. Image clarity check (OpenCV blur detection)
    2. Image compression (Pillow)
    3. Object / defect bounding box detection (YOLO)
    4. Multimodal severity triage (Gemini AI)
    """
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request, *args, **kwargs):
        serializer = ComplaintCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        image_file = request.FILES.get('image')
        if not image_file:
            return Response({"error": "Image file is required."}, status=status.HTTP_400_BAD_REQUEST)

        # 1. OpenCV Blur Detection
        is_clear, blur_score = validate_image_clarity(image_file)

        # 2. Pillow Image Compression
        compressed_file = compress_image(image_file)

        # Save initial complaint instance
        complaint = serializer.save(
            blur_score=blur_score,
            is_valid_image=is_clear,
            compressed_image=compressed_file
        )

        # 3. YOLO Defect Detection
        yolo_result = {}
        if complaint.image and hasattr(complaint.image, 'path') and os.path.exists(complaint.image.path):
            yolo_result = detect_civic_defects(complaint.image.path)
        complaint.yolo_detections = yolo_result

        # 4. Gemini Multimodal Analysis & Severity Scoring
        gemini_result = {}
        if complaint.image and hasattr(complaint.image, 'path') and os.path.exists(complaint.image.path):
            gemini_result = analyze_civic_issue(
                image_path=complaint.image.path,
                user_description=complaint.user_description
            )
            complaint.gemini_analysis = gemini_result
            if "severity_score" in gemini_result and isinstance(gemini_result["severity_score"], (int, float)):
                complaint.severity_score = int(gemini_result["severity_score"])

        complaint.save()

        detail_serializer = ComplaintDetailSerializer(complaint, context={'request': request})
        return Response(detail_serializer.data, status=status.HTTP_201_CREATED)


class ComplaintListView(generics.ListAPIView):
    """
    List complaints. Can be filtered by `user_identifier` or `status`.
    """
    serializer_class = ComplaintDetailSerializer

    def get_queryset(self):
        queryset = Complaint.objects.all()
        user_id = self.request.query_params.get('user_identifier')
        status_param = self.request.query_params.get('status')

        if user_id:
            queryset = queryset.filter(user_identifier=user_id)
        if status_param:
            queryset = queryset.filter(status=status_param)

        return queryset


class ComplaintDetailView(generics.RetrieveAPIView):
    """Retrieve full details of a specific complaint."""
    queryset = Complaint.objects.all()
    serializer_class = ComplaintDetailSerializer
    lookup_field = 'id'


class AdminMapMarkersView(generics.ListAPIView):
    """Lightweight endpoint returning coordinates and severities for OpenStreetMap visualization."""
    queryset = Complaint.objects.all()
    serializer_class = ComplaintMapMarkerSerializer
    pagination_class = None  # Return all markers for map rendering


class ComplaintStatusUpdateView(generics.UpdateAPIView):
    """Admin endpoint to update complaint status (RESOLVED, IN_PROGRESS, REJECTED) and notes."""
    queryset = Complaint.objects.all()
    serializer_class = ComplaintStatusUpdateSerializer
    lookup_field = 'id'


class HealthCheckView(APIView):
    """Health check endpoint for Docker container and frontend connectivity."""
    def get(self, request):
        return Response({
            "status": "healthy",
            "service": "ACTS Civic Triage Backend API",
            "version": "1.0.0"
        }, status=status.HTTP_200_OK)

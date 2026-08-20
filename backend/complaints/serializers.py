from rest_framework import serializers
from .models import Complaint, ComplaintStatus

class ComplaintCreateSerializer(serializers.ModelSerializer):
    """Serializer for multipart report submission from mobile/citizen."""
    class Meta:
        model = Complaint
        fields = [
            'id',
            'user_identifier',
            'image',
            'user_description',
            'latitude',
            'longitude',
            'address'
        ]
        read_only_fields = ['id']

class ComplaintDetailSerializer(serializers.ModelSerializer):
    """Full detail serializer for admin & review screens."""
    class Meta:
        model = Complaint
        fields = '__all__'

class ComplaintMapMarkerSerializer(serializers.ModelSerializer):
    """Lightweight serializer for map markers."""
    class Meta:
        model = Complaint
        fields = [
            'id',
            'latitude',
            'longitude',
            'severity_score',
            'status',
            'created_at'
        ]

class ComplaintStatusUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating status and administrative notes."""
    class Meta:
        model = Complaint
        fields = ['status', 'admin_notes']

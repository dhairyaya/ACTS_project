import uuid
from django.db import models

class ComplaintStatus(models.TextChoices):
    PENDING = 'PENDING', 'Pending Review'
    IN_PROGRESS = 'IN_PROGRESS', 'In Progress'
    RESOLVED = 'RESOLVED', 'Resolved'
    REJECTED = 'REJECTED', 'Rejected'

class Complaint(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_identifier = models.CharField(max_length=255, blank=True, null=True, help_text="Device ID or User ID")
    
    # Image & Description
    image = models.ImageField(upload_to='uploads/%Y/%m/%d/')
    compressed_image = models.ImageField(upload_to='uploads/compressed/%Y/%m/%d/', blank=True, null=True)
    user_description = models.TextField(blank=True, default='')

    # Location Information
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    address = models.CharField(max_length=500, blank=True, default='')

    # CV & AI Validation Results
    blur_score = models.FloatField(default=0.0, help_text="Laplacian variance blur metric")
    is_valid_image = models.BooleanField(default=True, help_text="False if image is overly blurry or invalid")
    
    # Detection & Severity
    yolo_detections = models.JSONField(default=dict, blank=True, help_text="Detected objects & bounding boxes")
    gemini_analysis = models.JSONField(default=dict, blank=True, help_text="Multimodal summary & civic taxonomy")
    severity_score = models.IntegerField(default=1, help_text="Calculated severity from 1 (Low) to 10 (Critical)")
    
    # Triage and Status
    status = models.CharField(
        max_length=20,
        choices=ComplaintStatus.choices,
        default=ComplaintStatus.PENDING
    )
    admin_notes = models.TextField(blank=True, default='')

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', '-created_at']),
            models.Index(fields=['latitude', 'longitude']),
        ]

    def __str__(self):
        return f"Complaint #{str(self.id)[:8]} - {self.status} (Severity: {self.severity_score}/10)"

from django.contrib import admin
from .models import Complaint

@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = ('id', 'status', 'severity_score', 'is_valid_image', 'latitude', 'longitude', 'created_at')
    list_filter = ('status', 'severity_score', 'is_valid_image', 'created_at')
    search_fields = ('id', 'user_description', 'address', 'user_identifier')
    readonly_fields = ('id', 'created_at', 'updated_at', 'blur_score')

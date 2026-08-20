from django.contrib import admin
from .models import Complaint, ComplaintCluster, MaintenanceCrew

@admin.register(MaintenanceCrew)
class MaintenanceCrewAdmin(admin.ModelAdmin):
    list_display = ('name', 'department', 'is_available', 'active_tasks_count', 'phone_number')
    list_filter = ('department', 'is_available')
    search_fields = ('name', 'phone_number')

@admin.register(ComplaintCluster)
class ComplaintClusterAdmin(admin.ModelAdmin):
    list_display = ('title', 'department', 'campus_zone', 'crowd_report_count', 'computed_priority', 'status', 'assigned_crew')
    list_filter = ('department', 'status', 'campus_zone')
    search_fields = ('title', 'campus_zone')
    ordering = ('-computed_priority',)

@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = ('id', 'raw_text', 'department', 'status', 'campus_zone', 'cluster', 'assigned_crew', 'created_at')
    list_filter = ('department', 'status', 'campus_zone')
    search_fields = ('raw_text', 'campus_zone', 'address', 'user_identifier')
    readonly_fields = ('id', 'created_at', 'updated_at', 'blur_score')

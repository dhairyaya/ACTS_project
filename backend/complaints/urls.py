from django.urls import path
from .views import (
    ComplaintCreateView,
    ComplaintListView,
    ComplaintDetailView,
    AdminMapMarkersView,
    ComplaintStatusUpdateView,
    HealthCheckView
)

urlpatterns = [
    # Health check
    path('health/', HealthCheckView.as_view(), name='health-check'),

    # Citizen endpoints
    path('complaints/report/', ComplaintCreateView.as_view(), name='complaint-report'),
    path('complaints/', ComplaintListView.as_view(), name='complaint-list'),
    path('complaints/<uuid:id>/', ComplaintDetailView.as_view(), name='complaint-detail'),

    # Admin endpoints
    path('admin/map-markers/', AdminMapMarkersView.as_view(), name='admin-map-markers'),
    path('admin/complaints/<uuid:id>/status/', ComplaintStatusUpdateView.as_view(), name='admin-update-status'),
]

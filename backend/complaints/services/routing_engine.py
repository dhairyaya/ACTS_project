import math
from typing import Optional, List, Dict, Any
from ..models import MaintenanceCrew, ComplaintCluster, ComplaintStatus

def find_best_crew_for_cluster(cluster: ComplaintCluster) -> Optional[MaintenanceCrew]:
    """
    Finds the most suitable maintenance crew for an infrastructure issue:
    1. Filters by department/skill
    2. Filters available crews
    3. Scores by distance + current workload weight
    """
    eligible_crews = MaintenanceCrew.objects.filter(
        department=cluster.department,
        is_available=True
    )

    if not eligible_crews.exists():
        # Fallback to general maintenance
        eligible_crews = MaintenanceCrew.objects.filter(is_available=True)

    if not eligible_crews.exists():
        return None

    best_crew = None
    lowest_score = float('inf')

    for crew in eligible_crews:
        # Distance calculation (or 0 if crew coordinates not known)
        distance_km = 0.5
        if crew.current_latitude and crew.current_longitude:
            lat_diff = float(cluster.latitude - crew.current_latitude)
            lon_diff = float(cluster.longitude - crew.current_longitude)
            distance_km = math.sqrt(lat_diff**2 + lon_diff**2) * 111.0  # Approx km per degree

        # Score formula: low distance + low workload is best
        score = (distance_km * 1.5) + (crew.active_tasks_count * 2.0)

        if score < lowest_score:
            lowest_score = score
            best_crew = crew

    return best_crew

def dispatch_cluster_to_crew(cluster: ComplaintCluster) -> Optional[MaintenanceCrew]:
    """
    Assigns the optimal crew to the cluster and updates cluster & complaint statuses.
    """
    crew = find_best_crew_for_cluster(cluster)
    if crew:
        cluster.assigned_crew = crew
        cluster.status = ComplaintStatus.ASSIGNED
        cluster.save()

        # Update all linked complaints
        cluster.reports.all().update(
            assigned_crew=crew,
            status=ComplaintStatus.ASSIGNED
        )

        crew.active_tasks_count += 1
        crew.save()

    return crew

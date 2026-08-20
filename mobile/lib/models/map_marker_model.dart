class MapMarkerModel {
  final String id;
  final String title;
  final String department;
  final String campusZone;
  final double latitude;
  final double longitude;
  final int crowdCount;
  final double computedPriority;
  final String status;
  final String? assignedCrewName;
  final DateTime createdAt;

  MapMarkerModel({
    required this.id,
    required this.title,
    required this.department,
    required this.campusZone,
    required this.latitude,
    required this.longitude,
    required this.crowdCount,
    required this.computedPriority,
    required this.status,
    this.assignedCrewName,
    required this.createdAt,
  });

  factory MapMarkerModel.fromJson(Map<String, dynamic> json) {
    return MapMarkerModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Campus Issue',
      department: json['department'] ?? 'GENERAL',
      campusZone: json['campus_zone'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      crowdCount: json['crowd_count'] ?? 1,
      computedPriority: (json['computed_priority'] as num?)?.toDouble() ?? 5.0,
      status: json['status'] ?? 'SUBMITTED',
      assignedCrewName: json['assigned_crew_name'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

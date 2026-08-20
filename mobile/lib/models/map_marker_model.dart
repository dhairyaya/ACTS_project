class MapMarkerModel {
  final String id;
  final double latitude;
  final double longitude;
  final int severityScore;
  final String status;
  final DateTime createdAt;

  MapMarkerModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.severityScore,
    required this.status,
    required this.createdAt,
  });

  factory MapMarkerModel.fromJson(Map<String, dynamic> json) {
    return MapMarkerModel(
      id: json['id'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      severityScore: json['severity_score'] ?? 1,
      status: json['status'] ?? 'PENDING',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

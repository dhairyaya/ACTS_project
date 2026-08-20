class ComplaintModel {
  final String id;
  final String? userIdentifier;
  final String imageUrl;
  final String? compressedImageUrl;
  final String userDescription;
  final double latitude;
  final double longitude;
  final String address;
  final double blurScore;
  final bool isValidImage;
  final Map<String, dynamic> yoloDetections;
  final Map<String, dynamic> geminiAnalysis;
  final int severityScore;
  final String status;
  final String adminNotes;
  final DateTime createdAt;

  ComplaintModel({
    required this.id,
    this.userIdentifier,
    required this.imageUrl,
    this.compressedImageUrl,
    required this.userDescription,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.blurScore,
    required this.isValidImage,
    required this.yoloDetections,
    required this.geminiAnalysis,
    required this.severityScore,
    required this.status,
    required this.adminNotes,
    required this.createdAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] ?? '',
      userIdentifier: json['user_identifier'],
      imageUrl: json['image'] ?? '',
      compressedImageUrl: json['compressed_image'],
      userDescription: json['user_description'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      address: json['address'] ?? '',
      blurScore: (json['blur_score'] as num?)?.toDouble() ?? 0.0,
      isValidImage: json['is_valid_image'] ?? true,
      yoloDetections: json['yolo_detections'] is Map ? Map<String, dynamic>.from(json['yolo_detections']) : {},
      geminiAnalysis: json['gemini_analysis'] is Map ? Map<String, dynamic>.from(json['gemini_analysis']) : {},
      severityScore: json['severity_score'] ?? 1,
      status: json['status'] ?? 'PENDING',
      adminNotes: json['admin_notes'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

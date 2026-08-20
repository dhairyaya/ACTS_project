import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import '../models/complaint_model.dart';
import '../models/map_marker_model.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'Accept': 'application/json',
                },
              ),
            );

  /// Plain-text complaint submission with optional photo & GPS auto-fill
  Future<Map<String, dynamic>> submitComplaint({
    required String rawText,
    required double latitude,
    required double longitude,
    File? imageFile,
    String? campusZone,
    String? address,
    String? userIdentifier,
  }) async {
    Map<String, dynamic> formMap = {
      'raw_text': rawText,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'campus_zone': campusZone ?? '',
      'address': address ?? '',
      if (userIdentifier != null) 'user_identifier': userIdentifier,
    };

    if (imageFile != null) {
      String fileName = imageFile.path.split(Platform.pathSeparator).last;
      formMap['image'] = await MultipartFile.fromFile(imageFile.path, filename: fileName);
    }

    FormData formData = FormData.fromMap(formMap);

    final response = await _dio.post(
      ApiConstants.reportComplaint,
      data: formData,
    );

    return response.data;
  }

  /// Fetches citizen submissions
  Future<List<ComplaintModel>> fetchMyComplaints({String? userIdentifier}) async {
    final response = await _dio.get(
      ApiConstants.listComplaints,
      queryParameters: userIdentifier != null ? {'user_identifier': userIdentifier} : null,
    );

    final List data = response.data['results'] ?? response.data;
    return data.map((json) => ComplaintModel.fromJson(json)).toList();
  }

  /// Fetches live crowd-weighted clusters for Admin Command Center Map
  Future<List<MapMarkerModel>> fetchMapMarkers() async {
    final response = await _dio.get(ApiConstants.adminMapMarkers);
    final List data = response.data is List ? response.data : (response.data['results'] ?? []);
    return data.map((json) => MapMarkerModel.fromJson(json)).toList();
  }

  /// Fetches single complaint detail
  Future<ComplaintModel> fetchComplaintDetail(String id) async {
    final response = await _dio.get('${ApiConstants.complaintDetail}$id/');
    return ComplaintModel.fromJson(response.data);
  }

  /// Step 6: Reporter 2-way confirmation or reopening of resolved issue
  Future<void> confirmResolution({
    required String complaintId,
    required bool isConfirmed,
    String? feedback,
  }) async {
    await _dio.post(
      '${ApiConstants.complaintDetail}$complaintId/confirm/',
      data: {
        'is_confirmed': isConfirmed,
        'feedback': feedback ?? '',
      },
    );
  }

  /// Section 5.4: Admin manual override of priority
  Future<void> overridePriority({
    required String clusterId,
    required double newPriority,
    String? adminNotes,
  }) async {
    await _dio.post(
      '/api/admin/clusters/$clusterId/override-priority/',
      data: {
        'priority': newPriority,
        'admin_notes': adminNotes ?? '',
      },
    );
  }

  /// Section 5.4: Campus Health Analytics
  Future<List<dynamic>> fetchCampusHealth() async {
    final response = await _dio.get('/api/admin/campus-health/');
    return response.data['campus_health'] ?? [];
  }

  /// Section 5.5: Admin Connect Portal direct directory
  Future<Map<String, dynamic>> fetchAdminConnect(String department) async {
    final response = await _dio.get(
      '/api/admin/connect/',
      queryParameters: {'department': department},
    );
    return response.data;
  }
}

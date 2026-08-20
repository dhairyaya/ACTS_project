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

  /// Submits a new complaint with image file and GPS metadata
  Future<ComplaintModel> submitComplaint({
    required File imageFile,
    required double latitude,
    required double longitude,
    String? userDescription,
    String? address,
    String? userIdentifier,
  }) async {
    String fileName = imageFile.path.split(Platform.pathSeparator).last;
    
    FormData formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'user_description': userDescription ?? '',
      'address': address ?? '',
      if (userIdentifier != null) 'user_identifier': userIdentifier,
    });

    final response = await _dio.post(
      ApiConstants.reportComplaint,
      data: formData,
    );

    return ComplaintModel.fromJson(response.data);
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

  /// Fetches lightweight map markers for admin view
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

  /// Updates complaint status and notes
  Future<void> updateComplaintStatus({
    required String id,
    required String status,
    String? adminNotes,
  }) async {
    await _dio.patch(
      '${ApiConstants.adminUpdateStatus}$id/status/',
      data: {
        'status': status,
        if (adminNotes != null) 'admin_notes': adminNotes,
      },
    );
  }
}

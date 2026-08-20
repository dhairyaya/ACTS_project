import 'dart:io';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/app_routes.dart';
import '../../services/api_client.dart';
import '../../services/camera_service.dart';
import '../../services/location_service.dart';
import '../../widgets/image_preview_card.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({Key? key}) : super(key: key);

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final CameraService _cameraService = CameraService();
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  File? _selectedImage;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _fetchGPS();
  }

  Future<void> _fetchGPS() async {
    setState(() => _isFetchingLocation = true);
    final pos = await LocationService.getCurrentLocation();
    if (pos != null) {
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    }
    setState(() => _isFetchingLocation = false);
  }

  Future<void> _pickImage(bool fromCamera) async {
    final file = fromCamera
        ? await _cameraService.captureImage()
        : await _cameraService.pickFromGallery();
    if (file != null) {
      setState(() => _selectedImage = file);
    }
  }

  Future<void> _submitReport() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture or select an issue photo')),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS coordinates missing. Retrying location fetch...')),
      );
      await _fetchGPS();
      if (_latitude == null || _longitude == null) return;
    }

    setState(() => _isLoading = true);
    try {
      final complaint = await _apiClient.submitComplaint(
        imageFile: _selectedImage!,
        latitude: _latitude!,
        longitude: _longitude!,
        userDescription: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Complaint Submitted! Severity Score: ${complaint.severityScore}/10'),
          backgroundColor: AppTheme.secondaryTeal,
        ),
      );

      setState(() {
        _selectedImage = null;
        _descriptionController.clear();
        _addressController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ACTS - Report Issue', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'My Reports',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.myReports),
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Admin Map',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.adminMap),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Picker Section
            if (_selectedImage != null)
              ImagePreviewCard(
                imageFile: _selectedImage,
                onRemove: () => setState(() => _selectedImage = null),
              )
            else
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 48, color: AppTheme.textMuted),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(true),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(false),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Location Info Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.my_location,
                      color: _latitude != null ? AppTheme.secondaryTeal : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isFetchingLocation
                            ? 'Fetching precise GPS coordinates...'
                            : (_latitude != null
                                ? 'GPS: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                                : 'Location unavailable. Tap refresh.'),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textDark),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _fetchGPS,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Address Input
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Landmark / Street Address (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Description Input
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Describe the civic issue...',
                hintText: 'e.g. Deep pothole causing waterlogging near main gate.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'SUBMIT COMPLAINT',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/app_routes.dart';
import '../../models/map_marker_model.dart';
import '../../services/api_client.dart';
import '../../widgets/custom_map_pin.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({Key? key}) : super(key: key);

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  final ApiClient _apiClient = ApiClient();
  final MapController _mapController = MapController();
  List<MapMarkerModel> _markers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    setState(() => _isLoading = true);
    try {
      final markers = await _apiClient.fetchMapMarkers();
      setState(() {
        _markers = markers;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load map markers: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default center (e.g. New Delhi / India or first marker position)
    LatLng initialCenter = _markers.isNotEmpty
        ? LatLng(_markers.first.latitude, _markers.first.longitude)
        : const LatLng(28.6139, 77.2090);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Civic Triage Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMarkers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.acts.mobile',
                ),
                MarkerLayer(
                  markers: _markers.map((marker) {
                    return Marker(
                      point: LatLng(marker.latitude, marker.longitude),
                      width: 40,
                      height: 40,
                      child: CustomMapPin(
                        severity: marker.severityScore,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.issueDetail,
                            arguments: marker.id,
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}

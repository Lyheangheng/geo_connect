import 'package:flutter/material.dart';
import 'package:geo_connect/core/theme/app_theme.dart';
import 'package:geo_connect/models/checkin_model.dart';
import 'package:geo_connect/widgets/checkin_card.dart';
import 'package:geo_connect/widgets/interactive_map_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock data for Phase 6 map & UI demo
  final List<CheckInModel> _mockCheckIns = [
    CheckInModel(
      id: 1,
      lat: 13.7563,
      lng: 100.5018,
      locationName: 'Bangkok Center',
      description: 'Studying Flutter assignment at the central library!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      user: CheckInUser(id: 2, name: 'Somsak Jaidee'),
    ),
    CheckInModel(
      id: 2,
      lat: 13.7367,
      lng: 100.5231,
      locationName: 'University Innovation Hub',
      description: 'Testing GeoConnect map pins with friends.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      user: CheckInUser(id: 3, name: 'Nok Ananda'),
    ),
  ];

  Set<Marker> _buildMarkers() {
    return _mockCheckIns.map((item) {
      return Marker(
        markerId: MarkerId(item.id.toString()),
        position: LatLng(item.lat, item.lng),
        infoWindow: InfoWindow(
          title: item.user?.name ?? 'Anonymous',
          snippet: item.description ?? '',
        ),
        onTap: () => _showCheckInDetails(item),
      );
    }).toSet();
  }

  void _showCheckInDetails(CheckInModel checkin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.pin_drop, color: AppTheme.secondaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      checkin.user?.name ?? 'Anonymous',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.cardColor, height: 24),
              Text(
                checkin.description ?? 'No description provided.',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Coordinates: (${checkin.lat.toStringAsFixed(6)}, ${checkin.lng.toStringAsFixed(6)})',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.subtextColor,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoConnect Map & Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshed check-ins list')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Interactive Google Maps View
            Container(
              width: double.infinity,
              height: 260,
              margin: const EdgeInsets.all(16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  InteractiveMapWidget(
                    initialPosition: const LatLng(13.7563, 100.5018),
                    initialZoom: 12.5,
                    markers: _buildMarkers(),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.secondaryColor),
                      ),
                      child: Text(
                        '${_mockCheckIns.length} Active Pins',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Check-ins Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent User Check-ins',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  Text(
                    '${_mockCheckIns.length} items',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.subtextColor,
                    ),
                  ),
                ],
              ),
            ),

            // Check-ins Feed List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _mockCheckIns.length,
              itemBuilder: (context, index) {
                final item = _mockCheckIns[index];
                return CheckInCard(
                  checkIn: item,
                  onTap: () => _showCheckInDetails(item),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

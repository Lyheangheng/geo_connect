import 'package:flutter/material.dart';
import 'package:geo_connect/core/errors/api_exception.dart';
import 'package:geo_connect/core/theme/app_theme.dart';
import 'package:geo_connect/models/checkin_model.dart';
import 'package:geo_connect/services/api_service.dart';
import 'package:geo_connect/widgets/checkin_card.dart';
import 'package:geo_connect/widgets/interactive_map_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();

  List<CheckInModel> _latestUserCheckIns = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCheckIns();
  }

  /// Fetches check-ins from GET /api/checking and groups them by User ID,
  /// keeping only the latest check-in for each user based on createdAt.
  Future<void> _fetchCheckIns() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawCheckIns = await _apiService.getCheckIns();
      final groupedCheckIns = _processGroupedUserCheckIns(rawCheckIns);

      if (!mounted) return;
      setState(() {
        _latestUserCheckIns = groupedCheckIns;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load check-ins. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  /// Groups check-ins by User ID and returns only the latest check-in for each user.
  List<CheckInModel> _processGroupedUserCheckIns(List<CheckInModel> rawCheckIns) {
    final Map<int, CheckInModel> userLatestMap = {};

    for (final item in rawCheckIns) {
      final userId = item.user?.id ?? item.userId;
      if (userId == null) continue;

      if (!userLatestMap.containsKey(userId)) {
        userLatestMap[userId] = item;
      } else {
        final existing = userLatestMap[userId]!;
        final currentCreatedAt = item.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final existingCreatedAt = existing.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        // Keep the check-in with the latest timestamp
        if (currentCreatedAt.isAfter(existingCreatedAt)) {
          userLatestMap[userId] = item;
        }
      }
    }

    final result = userLatestMap.values.toList();
    // Sort descending by createdAt
    result.sort((a, b) {
      final tA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tB.compareTo(tA);
    });
    return result;
  }

  Set<Marker> _buildMarkers() {
    return _latestUserCheckIns.map((item) {
      return Marker(
        markerId: MarkerId('user_${item.user?.id ?? item.id}'),
        position: LatLng(item.lat, item.lng),
        infoWindow: InfoWindow(
          title: item.user?.name ?? 'User #${item.userId ?? item.id}',
          snippet: item.locationName ?? item.description ?? 'Location Pin',
        ),
        onTap: () => _showCheckInDetails(item),
      );
    }).toSet();
  }

  void _showCheckInDetails(CheckInModel checkin) {
    final formattedTime = checkin.createdAt != null
        ? DateFormat('MMM d, y • HH:mm').format(checkin.createdAt!)
        : null;

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
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    child: Text(
                      (checkin.user?.name.isNotEmpty ?? false)
                          ? checkin.user!.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: AppTheme.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          checkin.user?.name ?? 'User #${checkin.userId ?? checkin.id}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        if (formattedTime != null)
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.subtextColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.cardColor, height: 24),

              if (checkin.locationName != null && checkin.locationName!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 18, color: AppTheme.primaryAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        checkin.locationName!,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              if (checkin.description != null && checkin.description!.isNotEmpty) ...[
                Text(
                  checkin.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (checkin.address != null && checkin.address!.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.subtextColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        checkin.address!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.subtextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.my_location, size: 14, color: AppTheme.subtextColor),
                    const SizedBox(width: 6),
                    Text(
                      'Lat: ${checkin.lat.toStringAsFixed(6)}, Lng: ${checkin.lng.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.subtextColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
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
    final defaultInitialPos = _latestUserCheckIns.isNotEmpty
        ? LatLng(_latestUserCheckIns.first.lat, _latestUserCheckIns.first.lng)
        : const LatLng(13.7563, 100.5018);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoConnect Map & Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCheckIns,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCheckIns,
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Interactive Google Maps View
              Container(
                width: double.infinity,
                height: 270,
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
                      initialPosition: defaultInitialPos,
                      initialZoom: 12.0,
                      markers: _buildMarkers(),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.secondaryColor),
                        ),
                        child: Text(
                          '${_latestUserCheckIns.length} Users Sharing',
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

              // Header Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Latest User Locations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    Text(
                      '${_latestUserCheckIns.length} users',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.subtextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Content States: Loading, Error, Empty, or Feed List
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                )
              else if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: AppTheme.errorColor),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textColor),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchCheckIns,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_latestUserCheckIns.isEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.location_off_outlined, size: 48, color: AppTheme.subtextColor),
                        SizedBox(height: 12),
                        Text(
                          'No shared user locations found yet.',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Be the first to share your location in the Location tab!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _latestUserCheckIns.length,
                  itemBuilder: (context, index) {
                    final item = _latestUserCheckIns[index];
                    return CheckInCard(
                      checkIn: item,
                      onTap: () => _showCheckInDetails(item),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

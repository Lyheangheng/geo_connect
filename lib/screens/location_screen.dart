import 'package:flutter/material.dart';
import 'package:geo_connect/core/errors/api_exception.dart';
import 'package:geo_connect/core/theme/app_theme.dart';
import 'package:geo_connect/models/checkin_model.dart';
import 'package:geo_connect/services/api_service.dart';
import 'package:geo_connect/widgets/custom_button.dart';
import 'package:geo_connect/widgets/custom_text_field.dart';
import 'package:geo_connect/widgets/interactive_map_widget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  // Selected location coordinates (Default: Bangkok Center 13.7563, 100.5018)
  double _selectedLat = 13.7563;
  double _selectedLng = 100.5018;

  CheckInModel? _existingCheckIn;
  bool _isLoadingInitial = true;
  bool _isSubmitting = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _fetchMyLatestCheckIn();
  }

  @override
  void dispose() {
    _locationNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Fetches the user's check-ins using GET /api/checking?my=true
  /// and pre-fills the latest check-in data.
  Future<void> _fetchMyLatestCheckIn() async {
    setState(() {
      _isLoadingInitial = true;
    });

    try {
      final myCheckIns = await _apiService.getMyCheckIns();
      if (myCheckIns.isNotEmpty) {
        // Sort descending by createdAt to find the latest
        myCheckIns.sort((a, b) {
          final tA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final tB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return tB.compareTo(tA);
        });

        final latest = myCheckIns.first;
        if (!mounted) return;
        setState(() {
          _existingCheckIn = latest;
          _selectedLat = latest.lat;
          _selectedLng = latest.lng;
          _locationNameController.text = latest.locationName ?? '';
          _descriptionController.text = latest.description ?? '';
        });
      }
    } catch (_) {
      // Ignore initial load error for seamless UI
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
        });
      }
    }
  }

  /// Saves (POST /api/checking) or Updates (PUT /api/checking) the check-in
  Future<void> _handleSubmitCheckIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final locationName = _locationNameController.text.trim();
        final description = _descriptionController.text.trim();

        if (_existingCheckIn != null) {
          // Update existing check-in (PUT /api/checking)
          await _apiService.updateCheckIn(
            id: _existingCheckIn!.id,
            locationName: locationName.isNotEmpty ? locationName : null,
            description: description.isNotEmpty ? description : null,
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check-in updated successfully!'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // Create new check-in (POST /api/checking)
          await _apiService.createCheckIn(
            lat: _selectedLat,
            lng: _selectedLng,
            locationName: locationName.isNotEmpty ? locationName : null,
            description: description.isNotEmpty ? description : null,
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location check-in saved successfully!'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        await _fetchMyLatestCheckIn();
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process check-in. Please try again.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  /// Deletes existing check-in (`DELETE /api/checking?id=id`)
  Future<void> _handleDeleteCheckIn() async {
    if (_existingCheckIn == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete Check-In', style: TextStyle(color: AppTheme.textColor)),
        content: const Text('Are you sure you want to delete your shared location check-in?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.subtextColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await _apiService.deleteCheckIn(id: _existingCheckIn!.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in deleted.'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Reset form state
      setState(() {
        _existingCheckIn = null;
        _locationNameController.clear();
        _descriptionController.clear();
        _selectedLat = 13.7563;
        _selectedLng = 100.5018;
      });

      await _fetchMyLatestCheckIn();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete check-in. Please try again.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPosition = LatLng(_selectedLat, _selectedLng);

    return Scaffold(
      appBar: AppBar(
        title: Text(_existingCheckIn != null ? 'Edit My Check-In' : 'Select Location & Check-In'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchMyLatestCheckIn,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingInitial
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Mode Status Badge
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _existingCheckIn != null
                              ? AppTheme.secondaryColor.withValues(alpha: 0.15)
                              : AppTheme.primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _existingCheckIn != null
                                ? AppTheme.secondaryColor
                                : AppTheme.primaryColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _existingCheckIn != null ? Icons.edit_location_alt : Icons.add_location_alt,
                              size: 20,
                              color: _existingCheckIn != null
                                  ? AppTheme.secondaryColor
                                  : AppTheme.primaryAccent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _existingCheckIn != null
                                    ? 'Editing Existing Check-In #${_existingCheckIn!.id}'
                                    : 'Creating New Location Check-In',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _existingCheckIn != null
                                      ? AppTheme.secondaryColor
                                      : AppTheme.primaryAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Live Interactive Google Map Picker
                      Container(
                        width: double.infinity,
                        height: 240,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.secondaryColor.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            InteractiveMapWidget(
                              initialPosition: selectedPosition,
                              initialZoom: 14.0,
                              markers: {
                                Marker(
                                  markerId: const MarkerId('selected_point'),
                                  position: selectedPosition,
                                  infoWindow: const InfoWindow(title: 'Check-in Position'),
                                ),
                              },
                              onTap: (point) {
                                setState(() {
                                  _selectedLat = point.latitude;
                                  _selectedLng = point.longitude;
                                });
                              },
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.touch_app, size: 14, color: AppTheme.secondaryColor),
                                    SizedBox(width: 6),
                                    Text(
                                      'Tap map to select location',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selected Coordinates Summary Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location, color: AppTheme.secondaryColor, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Selected Point: ${_selectedLat.toStringAsFixed(6)}, ${_selectedLng.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textColor,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Location Name Input
                      const Text(
                        'Location Name',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _locationNameController,
                        hintText: 'Place Name (e.g. Mahidol Central Library)',
                        prefixIcon: Icons.place_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a location name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description Input
                      const Text(
                        'Location Description',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _descriptionController,
                        hintText: 'What is happening at this location? (e.g. Studying at the library)',
                        prefixIcon: Icons.edit_note_outlined,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide a description for your check-in';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // Action Buttons
                      CustomButton(
                        text: _existingCheckIn != null ? 'Update Check-In' : 'Save Location Check-In',
                        isLoading: _isSubmitting,
                        icon: _existingCheckIn != null ? Icons.save_outlined : Icons.send_rounded,
                        onPressed: _handleSubmitCheckIn,
                      ),

                      if (_existingCheckIn != null) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: _isDeleting ? null : _handleDeleteCheckIn,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.errorColor, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: _isDeleting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.errorColor,
                                    ),
                                  )
                                : const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                            label: Text(
                              _isDeleting ? 'Deleting...' : 'Delete Check-In',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.errorColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

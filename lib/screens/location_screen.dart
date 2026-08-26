import 'package:flutter/material.dart';
import 'package:geo_connect/core/errors/api_exception.dart';
import 'package:geo_connect/core/theme/app_theme.dart';
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
  
  // Selected location coordinates (Default to Bangkok city center for demo)
  double _selectedLat = 13.7563;
  double _selectedLng = 100.5018;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _locationNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitCheckIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final locationName = _locationNameController.text.trim();
        final description = _descriptionController.text.trim();

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

        _locationNameController.clear();
        _descriptionController.clear();
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
            content: Text('Failed to save check-in. Please check your network connection.'),
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

  @override
  Widget build(BuildContext context) {
    final selectedPosition = LatLng(_selectedLat, _selectedLng);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location & Check-In'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                            infoWindow: const InfoWindow(title: 'Selected Check-in Location'),
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
                                'Tap map to pick location',
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

                // Save Button
                CustomButton(
                  text: 'Save Location Check-In',
                  isLoading: _isSubmitting,
                  icon: Icons.send_rounded,
                  onPressed: _handleSubmitCheckIn,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

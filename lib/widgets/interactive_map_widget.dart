import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class InteractiveMapWidget extends StatefulWidget {
  final LatLng initialPosition;
  final double initialZoom;
  final Set<Marker> markers;
  final void Function(LatLng point)? onTap;
  final void Function(GoogleMapController controller)? onMapCreated;
  final bool showCurrentLocationButton;
  final bool zoomControlsEnabled;

  const InteractiveMapWidget({
    super.key,
    this.initialPosition = const LatLng(13.7563, 100.5018), // Default: Bangkok Center
    this.initialZoom = 14.0,
    this.markers = const {},
    this.onTap,
    this.onMapCreated,
    this.showCurrentLocationButton = false,
    this.zoomControlsEnabled = true,
  });

  @override
  State<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends State<InteractiveMapWidget> {
  GoogleMapController? _controller;

  @override
  void didUpdateWidget(covariant InteractiveMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Move camera smoothly if initialPosition changes significantly
    if (oldWidget.initialPosition != widget.initialPosition && _controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLng(widget.initialPosition),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition,
        zoom: widget.initialZoom,
      ),
      markers: widget.markers,
      onTap: widget.onTap,
      myLocationEnabled: widget.showCurrentLocationButton,
      myLocationButtonEnabled: widget.showCurrentLocationButton,
      zoomControlsEnabled: widget.zoomControlsEnabled,
      compassEnabled: true,
      mapToolbarEnabled: true,
      onMapCreated: (controller) {
        _controller = controller;
        if (widget.onMapCreated != null) {
          widget.onMapCreated!(controller);
        }
      },
    );
  }
}

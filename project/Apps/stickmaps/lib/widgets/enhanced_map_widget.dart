import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class EnhancedMapWidget extends StatefulWidget {
  final Position? currentPosition;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final Function(GoogleMapController) onMapCreated;
  final VoidCallback? onMyLocationPressed;
  final bool showMyLocationButton;
  final bool showCompass;
  final double zoom;

  const EnhancedMapWidget({
    super.key,
    this.currentPosition,
    required this.markers,
    required this.polylines,
    required this.onMapCreated,
    this.onMyLocationPressed,
    this.showMyLocationButton = true,
    this.showCompass = true,
    this.zoom = 16.0,
  });

  @override
  State<EnhancedMapWidget> createState() => _EnhancedMapWidgetState();
}

class _EnhancedMapWidgetState extends State<EnhancedMapWidget> {
  GoogleMapController? _mapController;
  bool _isMapReady = false;

  // Enhanced map style for better visibility
  static const String _mapStyle = '''
[
  {
    "featureType": "poi",
    "elementType": "labels.icon",
    "stylers": [{"visibility": "simplified"}]
  },
  {
    "featureType": "poi.business",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#2c3e50"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#ffc107"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#64b5f6"}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#e8f5e9"}]
  }
]
''';

  @override
  Widget build(BuildContext context) {
    if (widget.currentPosition == null) {
      return _buildLoadingState();
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.currentPosition!.latitude,
              widget.currentPosition!.longitude,
            ),
            zoom: widget.zoom,
          ),
          markers: widget.markers,
          polylines: widget.polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: widget.showCompass,
          mapToolbarEnabled: false,
          buildingsEnabled: true,
          trafficEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            controller.setMapStyle(_mapStyle);
            widget.onMapCreated(controller);
            setState(() {
              _isMapReady = true;
            });
          },
          onCameraMove: (CameraPosition position) {
            // Optional: Handle camera movement
          },
        ),

        // Custom controls overlay
        if (_isMapReady) _buildMapControls(),

        // Loading overlay
        if (!_isMapReady) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue.shade700),
            const SizedBox(height: 16),
            Text(
              'Getting your location...',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue.shade700),
            const SizedBox(height: 16),
            Text(
              'Loading map...',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(),

          // Control buttons at bottom right
          Padding(
            padding: const EdgeInsets.only(right: 16, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Zoom In
                _buildControlButton(
                  icon: Icons.add,
                  onPressed: _zoomIn,
                  tooltip: 'Zoom in',
                ),

                const SizedBox(height: 8),

                // Zoom Out
                _buildControlButton(
                  icon: Icons.remove,
                  onPressed: _zoomOut,
                  tooltip: 'Zoom out',
                ),

                const SizedBox(height: 8),

                // My Location
                if (widget.showMyLocationButton)
                  _buildControlButton(
                    icon: Icons.my_location,
                    onPressed: widget.onMyLocationPressed ?? _goToMyLocation,
                    tooltip: 'My location',
                    isPrimary: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    bool isPrimary = false,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isPrimary ? Colors.blue.shade700 : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : Colors.blue.shade700,
            size: 24,
          ),
        ),
      ),
    );
  }

  Future<void> _zoomIn() async {
    if (_mapController != null) {
      final zoom = await _mapController!.getZoomLevel();
      await _mapController!.animateCamera(CameraUpdate.zoomTo(zoom + 1));
    }
  }

  Future<void> _zoomOut() async {
    if (_mapController != null) {
      final zoom = await _mapController!.getZoomLevel();
      await _mapController!.animateCamera(CameraUpdate.zoomTo(zoom - 1));
    }
  }

  Future<void> _goToMyLocation() async {
    if (_mapController != null && widget.currentPosition != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              widget.currentPosition!.latitude,
              widget.currentPosition!.longitude,
            ),
            zoom: 17,
            tilt: 45,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// Custom marker builder for better visibility
class CustomMarkerBuilder {
  static Future<BitmapDescriptor> createCustomMarker({
    required String label,
    required Color color,
    IconData icon = Icons.place,
  }) async {
    // For now, use default markers with custom hue
    double hue = 0.0;

    if (color == Colors.blue) {
      hue = BitmapDescriptor.hueBlue;
    } else if (color == Colors.red) {
      hue = BitmapDescriptor.hueRed;
    } else if (color == Colors.green) {
      hue = BitmapDescriptor.hueGreen;
    } else if (color == Colors.orange) {
      hue = BitmapDescriptor.hueOrange;
    } else if (color == Colors.yellow) {
      hue = BitmapDescriptor.hueYellow;
    }

    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  static Future<BitmapDescriptor> createHomeMarker() async {
    return await createCustomMarker(
      label: 'Home',
      color: Colors.blue,
      icon: Icons.home,
    );
  }

  static Future<BitmapDescriptor> createWorkMarker() async {
    return await createCustomMarker(
      label: 'Work',
      color: Colors.orange,
      icon: Icons.work,
    );
  }

  static Future<BitmapDescriptor> createFavoriteMarker() async {
    return await createCustomMarker(
      label: 'Favorite',
      color: Colors.red,
      icon: Icons.favorite,
    );
  }

  static Future<BitmapDescriptor> createDestinationMarker() async {
    return await createCustomMarker(
      label: 'Destination',
      color: Colors.red,
      icon: Icons.location_on,
    );
  }
}

// Polyline style helper
class PolylineStyleHelper {
  static Polyline createNavigationPolyline(
    List<LatLng> points, {
    String id = 'route',
    Color color = Colors.blue,
    int width = 6,
  }) {
    return Polyline(
      polylineId: PolylineId(id),
      points: points,
      color: color,
      width: width,
      patterns: [PatternItem.dash(30), PatternItem.gap(20)],
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
    );
  }

  static Polyline createAlternativeRoute(
    List<LatLng> points, {
    String id = 'alternative',
  }) {
    return Polyline(
      polylineId: PolylineId(id),
      points: points,
      color: Colors.grey,
      width: 4,
      patterns: [PatternItem.dot, PatternItem.gap(10)],
    );
  }
}

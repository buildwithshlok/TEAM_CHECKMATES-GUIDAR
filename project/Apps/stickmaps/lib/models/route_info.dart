import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteInfo {
  final String distance;
  final String duration;
  final List<LatLng> polylinePoints;
  final List<dynamic> steps;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.polylinePoints,
    required this.steps,
  });
}

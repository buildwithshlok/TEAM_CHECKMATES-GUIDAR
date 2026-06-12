import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class NavigationService {
  // Find closest point on route to current position
  int findClosestPointOnRoute(Position currentPos, List<LatLng> routePoints) {
    if (routePoints.isEmpty) return 0;

    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < routePoints.length; i++) {
      double distance = Geolocator.distanceBetween(
        currentPos.latitude,
        currentPos.longitude,
        routePoints[i].latitude,
        routePoints[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  // Detect upcoming turn
  Map<String, dynamic>? detectUpcomingTurn(
    List<LatLng> routePoints,
    int currentIndex, {
    int lookAheadPoints = 10,
  }) {
    if (currentIndex + lookAheadPoints >= routePoints.length) return null;

    LatLng current = routePoints[currentIndex];
    LatLng next = routePoints[currentIndex + 5];
    LatLng future = routePoints[currentIndex + lookAheadPoints];

    double bearing1 = _calculateBearing(current, next);
    double bearing2 = _calculateBearing(next, future);

    double bearingChange = (bearing2 - bearing1);
    if (bearingChange > 180) bearingChange -= 360;
    if (bearingChange < -180) bearingChange += 360;

    if (bearingChange.abs() < 30) return null; // No significant turn

    double distance = _calculateDistance(current, next);

    return {
      'direction': bearingChange < 0 ? 'Left' : 'Right',
      'distance': '${distance.round()} meters',
      'angle': bearingChange.abs(),
    };
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double startLat = start.latitude * math.pi / 180;
    double startLng = start.longitude * math.pi / 180;
    double endLat = end.latitude * math.pi / 180;
    double endLng = end.longitude * math.pi / 180;

    double y = math.sin(endLng - startLng) * math.cos(endLat);
    double x =
        math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(endLng - startLng);

    double bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }
}

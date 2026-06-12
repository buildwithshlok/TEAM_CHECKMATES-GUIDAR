import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationService {
  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  Stream<Position> get locationStream => _locationController.stream;
  StreamSubscription<Position>? _positionSubscription;

  Future<void> initialize() async {
    // Start listening to location updates
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
          ),
        ).listen((Position position) {
          _locationController.add(position);
        });
  }

  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  void dispose() {
    _positionSubscription?.cancel();
    _locationController.close();
  }
}

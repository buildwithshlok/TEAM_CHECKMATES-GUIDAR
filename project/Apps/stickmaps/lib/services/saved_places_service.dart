import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_place.dart';

class SavedPlacesService {
  static const String _savedPlacesKey = 'saved_places';

  // Get all saved places
  Future<List<SavedPlace>> getSavedPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? placesJson = prefs.getString(_savedPlacesKey);

      if (placesJson == null || placesJson.isEmpty) {
        return [];
      }

      final List<dynamic> placesList = jsonDecode(placesJson);
      return placesList.map((json) => SavedPlace.fromJson(json)).toList();
    } catch (e) {
      print('Error loading saved places: $e');
      return [];
    }
  }

  // Save a new place
  Future<bool> savePlace(SavedPlace place) async {
    try {
      final places = await getSavedPlaces();

      // Check for duplicates (same coordinates within 10 meters)
      bool isDuplicate = places.any((p) {
        double distance = _calculateDistance(
          p.latitude,
          p.longitude,
          place.latitude,
          place.longitude,
        );
        return distance < 10; // Within 10 meters
      });

      if (isDuplicate) {
        print('Place already saved');
        return false;
      }

      places.add(place);
      return await _savePlacesToStorage(places);
    } catch (e) {
      print('Error saving place: $e');
      return false;
    }
  }

  // Update an existing place
  Future<bool> updatePlace(SavedPlace updatedPlace) async {
    try {
      final places = await getSavedPlaces();
      final index = places.indexWhere((p) => p.id == updatedPlace.id);

      if (index == -1) {
        return false;
      }

      places[index] = updatedPlace;
      return await _savePlacesToStorage(places);
    } catch (e) {
      print('Error updating place: $e');
      return false;
    }
  }

  // Delete a place
  Future<bool> deletePlace(String id) async {
    try {
      final places = await getSavedPlaces();
      places.removeWhere((p) => p.id == id);
      return await _savePlacesToStorage(places);
    } catch (e) {
      print('Error deleting place: $e');
      return false;
    }
  }

  // Get a specific place by ID
  Future<SavedPlace?> getPlaceById(String id) async {
    try {
      final places = await getSavedPlaces();
      return places.firstWhere(
        (p) => p.id == id,
        orElse: () => throw Exception('Place not found'),
      );
    } catch (e) {
      print('Place not found: $e');
      return null;
    }
  }

  // Get places by category
  Future<List<SavedPlace>> getPlacesByCategory(String category) async {
    try {
      final places = await getSavedPlaces();
      return places.where((p) => p.category == category).toList();
    } catch (e) {
      print('Error filtering places: $e');
      return [];
    }
  }

  // Search saved places by name
  Future<List<SavedPlace>> searchPlaces(String query) async {
    try {
      final places = await getSavedPlaces();
      final lowerQuery = query.toLowerCase();

      return places.where((p) {
        return p.name.toLowerCase().contains(lowerQuery) ||
            p.address.toLowerCase().contains(lowerQuery) ||
            (p.notes?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  // Get recently saved places
  Future<List<SavedPlace>> getRecentPlaces({int limit = 5}) async {
    try {
      final places = await getSavedPlaces();
      places.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return places.take(limit).toList();
    } catch (e) {
      print('Error getting recent places: $e');
      return [];
    }
  }

  // Clear all saved places
  Future<bool> clearAllPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_savedPlacesKey);
    } catch (e) {
      print('Error clearing places: $e');
      return false;
    }
  }

  // Export places as JSON string
  Future<String> exportPlaces() async {
    try {
      final places = await getSavedPlaces();
      final List<Map<String, dynamic>> placesJson = places
          .map((p) => p.toJson())
          .toList();
      return jsonEncode(placesJson);
    } catch (e) {
      print('Error exporting places: $e');
      return '[]';
    }
  }

  // Import places from JSON string
  Future<bool> importPlaces(String jsonString) async {
    try {
      final List<dynamic> placesJson = jsonDecode(jsonString);
      final List<SavedPlace> newPlaces = placesJson
          .map((json) => SavedPlace.fromJson(json))
          .toList();

      final existingPlaces = await getSavedPlaces();

      // Merge without duplicates
      for (var newPlace in newPlaces) {
        bool isDuplicate = existingPlaces.any((existing) {
          double distance = _calculateDistance(
            existing.latitude,
            existing.longitude,
            newPlace.latitude,
            newPlace.longitude,
          );
          return distance < 10;
        });

        if (!isDuplicate) {
          existingPlaces.add(newPlace);
        }
      }

      return await _savePlacesToStorage(existingPlaces);
    } catch (e) {
      print('Error importing places: $e');
      return false;
    }
  }

  // Private helper to save places to storage
  Future<bool> _savePlacesToStorage(List<SavedPlace> places) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> placesJson = places
          .map((p) => p.toJson())
          .toList();
      final String jsonString = jsonEncode(placesJson);
      return await prefs.setString(_savedPlacesKey, jsonString);
    } catch (e) {
      print('Error saving to storage: $e');
      return false;
    }
  }

  // Calculate distance between two coordinates (in meters)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  double sin(double radians) => math.sin(radians);
  double cos(double radians) => math.cos(radians);
  double sqrt(double value) => math.sqrt(value);
  double atan2(double y, double x) => math.atan2(y, x);

  static const double pi = 3.141592653589793;

  // Using dart:math for mathematical functions
  static final math = _Math();
}

class _Math {
  double sin(double x) => _sin(x);
  double cos(double x) => _cos(x);
  double sqrt(double x) => _sqrt(x);
  double atan2(double y, double x) => _atan2(y, x);

  double _sin(double x) {
    // Taylor series approximation for sin
    double result = 0;
    for (int n = 0; n < 10; n++) {
      double term = _pow(-1, n) * _pow(x, 2 * n + 1) / _factorial(2 * n + 1);
      result += term;
    }
    return result;
  }

  double _cos(double x) {
    double result = 0;
    for (int n = 0; n < 10; n++) {
      double term = _pow(-1, n) * _pow(x, 2 * n) / _factorial(2 * n);
      result += term;
    }
    return result;
  }

  double _sqrt(double x) {
    if (x < 0) return double.nan;
    if (x == 0) return 0;

    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return double.nan;
  }

  double _atan(double x) {
    // Taylor series for atan (works best for |x| < 1)
    if (x.abs() > 1) {
      return (3.141592653589793 / 2) - _atan(1 / x);
    }

    double result = 0;
    for (int n = 0; n < 20; n++) {
      double term = _pow(-1, n) * _pow(x, 2 * n + 1) / (2 * n + 1);
      result += term;
    }
    return result;
  }

  double _pow(double base, int exp) {
    if (exp == 0) return 1;
    double result = 1;
    for (int i = 0; i < exp.abs(); i++) {
      result *= base;
    }
    return exp < 0 ? 1 / result : result;
  }

  double _factorial(int n) {
    if (n <= 1) return 1;
    double result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }
}

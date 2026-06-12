import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../models/predicted_place.dart';
import '../models/route_info.dart';

class MapsApiService {
  static const String apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // Enhanced place search with location bias and ranking
  Future<List<PredictedPlace>> searchPlacesAdvanced(
    String query,
    Position currentPosition,
  ) async {
    try {
      // First try Places API autocomplete with location bias
      String autocompleteUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json"
          "?input=${Uri.encodeComponent(query)}"
          "&location=${currentPosition.latitude},${currentPosition.longitude}"
          "&radius=50000"
          "&key=$apiKey"
          "&components=country:in";

      var response = await http.get(Uri.parse(autocompleteUrl));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data["status"] == "OK" && data["predictions"] != null) {
          List<PredictedPlace> places = [];
          for (var prediction in data["predictions"]) {
            places.add(PredictedPlace.fromJson(prediction));
          }

          if (places.isNotEmpty) {
            return places;
          }
        }
      }

      // If autocomplete fails, try nearby search
      return await _nearbySearch(query, currentPosition);
    } catch (e) {
      print("Enhanced search error: $e");
      return [];
    }
  }

  // Nearby search as fallback
  Future<List<PredictedPlace>> _nearbySearch(
    String query,
    Position currentPosition,
  ) async {
    try {
      String nearbyUrl =
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
          "?location=${currentPosition.latitude},${currentPosition.longitude}"
          "&radius=10000"
          "&keyword=${Uri.encodeComponent(query)}"
          "&key=$apiKey";

      var response = await http.get(Uri.parse(nearbyUrl));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        if (data["status"] == "OK" && data["results"] != null) {
          List<PredictedPlace> places = [];

          for (var result in data["results"]) {
            // Convert nearby search result to PredictedPlace format
            places.add(
              PredictedPlace(
                placeId: result["place_id"] ?? "",
                mainText: result["name"] ?? "",
                secondaryText: result["vicinity"] ?? "",
              ),
            );
          }

          return places;
        }
      }

      return [];
    } catch (e) {
      print("Nearby search error: $e");
      return [];
    }
  }

  // Original search method (kept for backward compatibility)
  Future<List<PredictedPlace>> searchPlaces(String query) async {
    String url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
        "?input=${Uri.encodeComponent(query)}&key=$apiKey&components=country:in";

    var response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to search places');
    }

    var data = jsonDecode(response.body);

    if (data["status"] != "OK") {
      return [];
    }

    List<PredictedPlace> places = [];
    for (var prediction in data["predictions"]) {
      places.add(PredictedPlace.fromJson(prediction));
    }

    return places;
  }

  // Get place details with error handling
  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    try {
      String url =
          "https://maps.googleapis.com/maps/api/place/details/json"
          "?place_id=${Uri.encodeComponent(placeId)}"
          "&fields=geometry,formatted_address,name,types"
          "&key=$apiKey";

      var response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to get place details');
      }

      var data = jsonDecode(response.body);

      if (data["status"] != "OK") {
        throw Exception('Place not found: ${data["status"]}');
      }

      var result = data["result"];
      var geometry = result["geometry"]["location"];

      return {
        'lat': geometry["lat"],
        'lng': geometry["lng"],
        'address': result["formatted_address"] ?? "",
        'name': result["name"] ?? "",
        'types': result["types"] ?? [],
      };
    } catch (e) {
      print("Place details error: $e");
      rethrow;
    }
  }

  // Enhanced directions with alternative routes
  Future<RouteInfo> getDirections(
    Position origin,
    LatLng destination, {
    bool alternatives = false,
  }) async {
    try {
      String url =
          "https://maps.googleapis.com/maps/api/directions/json"
          "?origin=${origin.latitude},${origin.longitude}"
          "&destination=${destination.latitude},${destination.longitude}"
          "&mode=walking"
          "&alternatives=${alternatives ? 'true' : 'false'}"
          "&key=$apiKey";

      var response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to get directions: ${response.statusCode}');
      }

      var data = jsonDecode(response.body);

      if (data["status"] != "OK") {
        throw Exception('Route not found: ${data["status"]}');
      }

      var route = data["routes"][0];
      var leg = route["legs"][0];

      // Decode polyline with better error handling
      String encodedPolyline = route["overview_polyline"]["points"];
      List<LatLng> polylineCoordinates = [];

      try {
        List<PointLatLng> points = PolylinePoints.decodePolyline(
          encodedPolyline,
        );
        polylineCoordinates = points
            .map((e) => LatLng(e.latitude, e.longitude))
            .toList();
      } catch (e) {
        print("Polyline decode error: $e");
        // Fallback: create simple straight line
        polylineCoordinates = [
          LatLng(origin.latitude, origin.longitude),
          destination,
        ];
      }

      // Ensure we have at least 2 points
      if (polylineCoordinates.length < 2) {
        polylineCoordinates = [
          LatLng(origin.latitude, origin.longitude),
          destination,
        ];
      }

      return RouteInfo(
        distance: leg["distance"]["text"] ?? "Unknown distance",
        duration: leg["duration"]["text"] ?? "Unknown duration",
        polylinePoints: polylineCoordinates,
        steps: leg["steps"] ?? [],
      );
    } catch (e) {
      print("Directions error: $e");
      rethrow;
    }
  }

  // Reverse geocoding to get address from coordinates
  Future<String?> reverseGeocode(Position position) async {
    try {
      String url =
          "https://maps.googleapis.com/maps/api/geocode/json"
          "?latlng=${position.latitude},${position.longitude}"
          "&result_type=street_address|route|neighborhood|locality"
          "&key=$apiKey";

      var response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return null;
      }

      var data = jsonDecode(response.body);

      if (data["status"] == "OK" &&
          data["results"] != null &&
          data["results"].isNotEmpty) {
        // Try to get a concise address
        for (var result in data["results"]) {
          List<dynamic> addressComponents = result["address_components"] ?? [];

          String? street;
          String? area;
          String? city;

          for (var component in addressComponents) {
            List<dynamic> types = component["types"] ?? [];

            if (types.contains("route") && street == null) {
              street = component["long_name"];
            } else if (types.contains("sublocality") && area == null) {
              area = component["long_name"];
            } else if (types.contains("locality") && city == null) {
              city = component["long_name"];
            }
          }

          // Build concise address
          List<String> parts = [];
          if (street != null) parts.add(street);
          if (area != null && area != street) parts.add(area);
          if (city != null && city != area) parts.add(city);

          if (parts.isNotEmpty) {
            return parts.join(", ");
          }
        }

        // Fallback to first formatted address
        return data["results"][0]["formatted_address"];
      }

      return null;
    } catch (e) {
      print("Reverse geocode error: $e");
      return null;
    }
  }

  // Get place details by coordinates (useful for selecting nearby places)
  Future<List<Map<String, dynamic>>> getPlacesNearby(
    Position position,
    String type, {
    int radius = 1000,
  }) async {
    try {
      String url =
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
          "?location=${position.latitude},${position.longitude}"
          "&radius=$radius"
          "&type=$type"
          "&key=$apiKey";

      var response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return [];
      }

      var data = jsonDecode(response.body);

      if (data["status"] == "OK" && data["results"] != null) {
        List<Map<String, dynamic>> places = [];

        for (var result in data["results"]) {
          places.add({
            'place_id': result["place_id"],
            'name': result["name"],
            'vicinity': result["vicinity"],
            'rating': result["rating"],
            'location': {
              'lat': result["geometry"]["location"]["lat"],
              'lng': result["geometry"]["location"]["lng"],
            },
          });
        }

        return places;
      }

      return [];
    } catch (e) {
      print("Nearby places error: $e");
      return [];
    }
  }

  // Calculate accurate distance between two points
  double calculateDistance(Position from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }
}

class PredictedPlace {
  final String placeId;
  final String mainText;
  final String secondaryText;
  double? distance; // Distance from current location in meters
  String? formattedDistance; // Human-readable distance

  PredictedPlace({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    this.distance,
    this.formattedDistance,
  });

  factory PredictedPlace.fromJson(Map<String, dynamic> json) {
    // Handle both autocomplete and nearby search formats
    if (json.containsKey("structured_formatting")) {
      // Autocomplete format
      return PredictedPlace(
        placeId: json["place_id"] ?? "",
        mainText: json["structured_formatting"]["main_text"] ?? "",
        secondaryText: json["structured_formatting"]["secondary_text"] ?? "",
      );
    } else {
      // Nearby search format or simple format
      return PredictedPlace(
        placeId: json["place_id"] ?? "",
        mainText: json["name"] ?? json["mainText"] ?? "",
        secondaryText: json["vicinity"] ?? json["secondaryText"] ?? "",
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "place_id": placeId,
      "mainText": mainText,
      "secondaryText": secondaryText,
      "distance": distance,
      "formattedDistance": formattedDistance,
    };
  }

  // Set distance and auto-format it
  void setDistance(double distanceInMeters) {
    distance = distanceInMeters;

    if (distanceInMeters < 1000) {
      formattedDistance = "${distanceInMeters.round()} meters";
    } else {
      formattedDistance = "${(distanceInMeters / 1000).toStringAsFixed(1)} km";
    }
  }

  // Get a readable description including distance
  String get fullDescription {
    String desc = mainText;
    if (secondaryText.isNotEmpty) {
      desc += " - $secondaryText";
    }
    if (formattedDistance != null) {
      desc += " ($formattedDistance away)";
    }
    return desc;
  }

  @override
  String toString() {
    return 'PredictedPlace{placeId: $placeId, mainText: $mainText, secondaryText: $secondaryText, distance: $distance}';
  }
}

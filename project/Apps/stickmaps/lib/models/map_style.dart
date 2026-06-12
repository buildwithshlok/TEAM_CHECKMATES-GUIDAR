class MapStyle {
  // Standard map style with enhanced visibility
  static const String standard = '''
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

  // High contrast mode for better visibility
  static const String highContrast = '''
[
  {
    "featureType": "all",
    "elementType": "labels",
    "stylers": [{"visibility": "on"}]
  },
  {
    "featureType": "all",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#000000"}, {"weight": "0.20"}]
  },
  {
    "featureType": "all",
    "elementType": "labels.text.stroke",
    "stylers": [{"visibility": "on"}, {"color": "#ffffff"}, {"weight": "2.00"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#000000"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#ff9800"}, {"weight": "1.00"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#2196f3"}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  }
]
''';

  // Night mode for low light conditions
  static const String night = '''
[
  {
    "featureType": "all",
    "elementType": "geometry",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "featureType": "all",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "all",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#242f3e"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#38414e"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#746855"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#17263c"}]
  }
]
''';

  // Simple mode with minimal details
  static const String simple = '''
[
  {
    "featureType": "poi",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "administrative",
    "stylers": [{"visibility": "simplified"}]
  }
]
''';
}

// Map configuration settings
class MapConfiguration {
  final bool showTraffic;
  final bool showBuildings;
  final bool showMyLocation;
  final bool showCompass;
  final bool showZoomControls;
  final double defaultZoom;
  final double navigationZoom;
  final MapStyleType styleType;

  const MapConfiguration({
    this.showTraffic = false,
    this.showBuildings = true,
    this.showMyLocation = true,
    this.showCompass = true,
    this.showZoomControls = false,
    this.defaultZoom = 16.0,
    this.navigationZoom = 18.0,
    this.styleType = MapStyleType.standard,
  });

  String get mapStyle {
    switch (styleType) {
      case MapStyleType.standard:
        return MapStyle.standard;
      case MapStyleType.highContrast:
        return MapStyle.highContrast;
      case MapStyleType.night:
        return MapStyle.night;
      case MapStyleType.simple:
        return MapStyle.simple;
    }
  }

  MapConfiguration copyWith({
    bool? showTraffic,
    bool? showBuildings,
    bool? showMyLocation,
    bool? showCompass,
    bool? showZoomControls,
    double? defaultZoom,
    double? navigationZoom,
    MapStyleType? styleType,
  }) {
    return MapConfiguration(
      showTraffic: showTraffic ?? this.showTraffic,
      showBuildings: showBuildings ?? this.showBuildings,
      showMyLocation: showMyLocation ?? this.showMyLocation,
      showCompass: showCompass ?? this.showCompass,
      showZoomControls: showZoomControls ?? this.showZoomControls,
      defaultZoom: defaultZoom ?? this.defaultZoom,
      navigationZoom: navigationZoom ?? this.navigationZoom,
      styleType: styleType ?? this.styleType,
    );
  }
}

enum MapStyleType { standard, highContrast, night, simple }

// Marker configurations
class MarkerConfiguration {
  static const double currentLocationSize = 12.0;
  static const double destinationSize = 40.0;
  static const double savedPlaceSize = 36.0;

  // Marker hues for different types
  static const double currentLocationHue = 211.0; // Blue
  static const double destinationHue = 0.0; // Red
  static const double homeHue = 211.0; // Blue
  static const double workHue = 30.0; // Orange
  static const double favoriteHue = 0.0; // Red
  static const double otherHue = 120.0; // Green
}

// Polyline configurations
class PolylineConfiguration {
  static const int navigationWidth = 6;
  static const int alternativeWidth = 4;

  // Colors
  static const navigationColor = 0xFF2196F3; // Blue
  static const alternativeColor = 0xFF9E9E9E; // Grey
  static const offRouteColor = 0xFFF44336; // Red
}

// Camera configurations
class CameraConfiguration {
  static const double defaultZoom = 16.0;
  static const double navigationZoom = 18.0;
  static const double detailZoom = 20.0;
  static const double overviewZoom = 14.0;

  static const double defaultTilt = 0.0;
  static const double navigationTilt = 45.0;

  static const double defaultBearing = 0.0;

  // Animation durations
  static const int normalAnimationMs = 1000;
  static const int fastAnimationMs = 500;
  static const int slowAnimationMs = 2000;
}

// Map bounds padding
class MapPadding {
  static const double top = 100.0;
  static const double bottom = 200.0;
  static const double left = 50.0;
  static const double right = 50.0;

  static const double navigationTop = 150.0;
  static const double navigationBottom = 300.0;
}

// Distance thresholds
class MapDistanceThresholds {
  static const double closeDistance = 100.0; // meters
  static const double mediumDistance = 500.0; // meters
  static const double farDistance = 2000.0; // meters

  static const double arrivalThreshold = 30.0; // meters
  static const double offRouteThreshold = 50.0; // meters
  static const double recalculateThreshold = 100.0; // meters
}

// Map gesture settings
class MapGestureSettings {
  final bool rotateEnabled;
  final bool tiltEnabled;
  final bool zoomEnabled;
  final bool scrollEnabled;

  const MapGestureSettings({
    this.rotateEnabled = true,
    this.tiltEnabled = true,
    this.zoomEnabled = true,
    this.scrollEnabled = true,
  });

  MapGestureSettings copyWith({
    bool? rotateEnabled,
    bool? tiltEnabled,
    bool? zoomEnabled,
    bool? scrollEnabled,
  }) {
    return MapGestureSettings(
      rotateEnabled: rotateEnabled ?? this.rotateEnabled,
      tiltEnabled: tiltEnabled ?? this.tiltEnabled,
      zoomEnabled: zoomEnabled ?? this.zoomEnabled,
      scrollEnabled: scrollEnabled ?? this.scrollEnabled,
    );
  }

  // Preset: Locked for navigation
  static const MapGestureSettings navigationLocked = MapGestureSettings(
    rotateEnabled: false,
    tiltEnabled: false,
    zoomEnabled: true,
    scrollEnabled: false,
  );

  // Preset: Free exploration
  static const MapGestureSettings freeExploration = MapGestureSettings(
    rotateEnabled: true,
    tiltEnabled: true,
    zoomEnabled: true,
    scrollEnabled: true,
  );
}

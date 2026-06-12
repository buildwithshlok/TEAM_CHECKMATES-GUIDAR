import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stickmaps/services/aI_multilingual_search_service.dart';
import 'package:stickmaps/services/multilingual_service.dart';
import 'package:stickmaps/services/wifi_service.dart';
import 'dart:async';
import '../services/speech_service.dart';
import '../services/location_service.dart';
import '../services/navigation_service.dart';
import '../services/maps_api_service.dart';
import '../services/ai_assistant_service.dart';
import '../services/saved_places_service.dart';
import '../models/predicted_place.dart';
import '../models/route_info.dart';
import '../models/saved_place.dart';

enum AppState {
  idle,
  listening,
  processing,
  browsingResults,
  navigating,
  browsingSavedPlaces,
}

class NavigationController extends ChangeNotifier {
  final WiFiService wifiService = WiFiService();
  final EnhancedSpeechService speechService = EnhancedSpeechService();
  final AIMultilingualSearchService aiSearchService =
      AIMultilingualSearchService();

  final LocationService locationService = LocationService();
  final NavigationService navigationService = NavigationService();
  final MapsApiService mapsApiService = MapsApiService();
  final AIAssistantService aiAssistant = AIAssistantService();
  final SavedPlacesService savedPlacesService = SavedPlacesService();

  // State
  AppState _currentState = AppState.idle;
  Position? _currentPosition;
  String? _currentAddress;

  // Obstacle detection state
  List<ObstacleData> _currentObstacles = [];
  Map<String, DateTime> _lastAnnouncedObstacles = {
    'HEAD': DateTime.now().subtract(const Duration(hours: 1)),
    'MID': DateTime.now().subtract(const Duration(hours: 1)),
    'GROUND': DateTime.now().subtract(const Duration(hours: 1)),
  };
  final Duration _obstacleAnnouncementCooldown = const Duration(seconds: 3);

  // Search and navigation
  List<PredictedPlace> _searchResults = [];
  List<SavedPlace> _savedPlaces = [];
  int _currentResultIndex = 0;
  int _currentSavedPlaceIndex = 0;
  PredictedPlace? _selectedDestination;
  RouteInfo? _routeInfo;
  String _lastSpokenText = "";

  // Map data
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  GoogleMapController? _mapController;

  // Navigation tracking
  Timer? _navigationTimer;
  int _currentStepIndex = 0;
  List<LatLng> _routePoints = [];
  double _lastAnnouncedDistance = 0;
  DateTime? _lastTurnAnnouncement;
  DateTime? _lastDistanceAnnouncement;
  bool _offRoute = false;

  // Speech queue management
  bool _isProcessingSpeech = false;
  final List<String> _speechQueue = [];

  // Getters
  AppState get currentState => _currentState;
  bool get isWiFiConnected => wifiService.isConnected;
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  List<PredictedPlace> get searchResults => _searchResults;
  List<SavedPlace> get savedPlaces => _savedPlaces;
  int get currentResultIndex => _currentResultIndex;
  int get currentSavedPlaceIndex => _currentSavedPlaceIndex;
  PredictedPlace? get selectedDestination => _selectedDestination;
  RouteInfo? get routeInfo => _routeInfo;
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  bool get isNavigating => _currentState == AppState.navigating;
  String get lastSpokenText => _lastSpokenText;
  List<ObstacleData> get currentObstacles => _currentObstacles;

  NavigationController() {
    _initialize();
  }

  Future<void> _initialize() async {
    await speechService.initialize();
    await locationService.initialize();

    _currentPosition = await locationService.getCurrentLocation();
    await _updateCurrentAddress();

    // Load saved places
    _savedPlaces = await savedPlacesService.getSavedPlaces();
    notifyListeners();

    // Listen to button presses
    wifiService.buttonPressStream.listen(_handleButtonPress);

    // Listen to WiFi connection
    wifiService.connectionStream.listen((connected) {
      if (connected) {
        _queueSpeech("Bluetooth connected successfully.");
      } else {
        _queueSpeech("Bluetooth disconnected. Please reconnect your stick.");
      }
      notifyListeners();
    });

    // Listen to obstacle detection
    wifiService.obstacleStream.listen(_handleObstacleDetection);

    // Listen to location updates
    locationService.locationStream.listen((position) {
      _currentPosition = position;
      _updateCurrentLocationMarker();

      if (_currentState == AppState.navigating) {
        _checkNavigationProgress();
      }

      notifyListeners();
    });

    await Future.delayed(const Duration(seconds: 1));
    await _announceWelcomeWithContext();
  }

  // ==================== OBSTACLE DETECTION HANDLING ====================
  void _handleObstacleDetection(List<ObstacleData> obstacles) {
    _currentObstacles = obstacles;
    notifyListeners();

    // Only announce obstacles when not navigating or when idle
    // During navigation, we don't want obstacle warnings to interrupt turn-by-turn directions
    if (_currentState == AppState.idle ||
        _currentState == AppState.browsingResults) {
      _announceObstacles(obstacles);
    }
  }

  Future<void> _announceObstacles(List<ObstacleData> obstacles) async {
    final now = DateTime.now();

    // Priority: Critical obstacles first
    List<ObstacleData> criticalObstacles = obstacles
        .where((o) => o.isCritical)
        .toList();
    List<ObstacleData> highObstacles = obstacles
        .where((o) => o.isHigh)
        .toList();

    // Announce critical obstacles immediately
    for (var obstacle in criticalObstacles) {
      final lastAnnounced = _lastAnnouncedObstacles[obstacle.sensor]!;

      if (now.difference(lastAnnounced) > _obstacleAnnouncementCooldown) {
        String announcement = _getObstacleAnnouncement(obstacle);
        await _queueSpeech(announcement, priority: true);
        _lastAnnouncedObstacles[obstacle.sensor] = now;
      }
    }

    // Announce high severity obstacles with longer cooldown
    if (criticalObstacles.isEmpty) {
      for (var obstacle in highObstacles) {
        final lastAnnounced = _lastAnnouncedObstacles[obstacle.sensor]!;

        if (now.difference(lastAnnounced) > const Duration(seconds: 5)) {
          String announcement = _getObstacleAnnouncement(obstacle);
          await _queueSpeech(announcement);
          _lastAnnouncedObstacles[obstacle.sensor] = now;
        }
      }
    }
  }

  String _getObstacleAnnouncement(ObstacleData obstacle) {
    String levelText = "";

    switch (obstacle.sensor) {
      case "HEAD":
        levelText = MultilingualService.currentLanguage == AppLanguage.hindi
            ? "सिर के स्तर पर"
            : "at head level";
        break;
      case "MID":
        levelText = MultilingualService.currentLanguage == AppLanguage.hindi
            ? "कमर के स्तर पर"
            : "at Ground level";
        break;
      case "GROUND":
        levelText = MultilingualService.currentLanguage == AppLanguage.hindi
            ? "जमीन पर"
            : "on the ground";
        break;
    }

    String distanceText = "";
    if (obstacle.distance < 30) {
      distanceText = MultilingualService.currentLanguage == AppLanguage.hindi
          ? "बहुत पास"
          : "very close";
    } else if (obstacle.distance < 60) {
      distanceText = MultilingualService.currentLanguage == AppLanguage.hindi
          ? "पास"
          : "nearby";
    } else {
      distanceText = MultilingualService.currentLanguage == AppLanguage.hindi
          ? "आगे"
          : "ahead";
    }

    String warning = MultilingualService.currentLanguage == AppLanguage.hindi
        ? "सावधान"
        : "Caution";

    String obstacle_text =
        MultilingualService.currentLanguage == AppLanguage.hindi
        ? "बाधा"
        : "obstacle";

    return "$warning! $obstacle_text $levelText, $distanceText. ${obstacle.distance} ${MultilingualService.t('centimeters')}";
  }

  // ==================== SPEECH QUEUE MANAGEMENT ====================
  Future<void> _queueSpeech(String text, {bool priority = false}) async {
    if (priority) {
      await speechService.stop();
      _speechQueue.clear();
      await _speakNow(text);
    } else {
      _speechQueue.add(text);
      _processSpeechQueue();
    }
  }

  Future<void> _processSpeechQueue() async {
    if (_isProcessingSpeech || _speechQueue.isEmpty) return;

    _isProcessingSpeech = true;

    while (_speechQueue.isNotEmpty) {
      String text = _speechQueue.removeAt(0);
      await _speakNow(text);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _isProcessingSpeech = false;
  }

  Future<void> _speakNow(String text) async {
    _lastSpokenText = text;
    notifyListeners();
    await speechService.speak(text);
  }

  // ==================== ADDRESS AND WELCOME ====================
  Future<void> _updateCurrentAddress() async {
    if (_currentPosition != null) {
      _currentAddress = await mapsApiService.reverseGeocode(_currentPosition!);
    }
  }

  Future<void> _announceWelcomeWithContext() async {
    await _updateCurrentAddress();
    String welcome = "${MultilingualService.t('welcome')}. ";

    if (_currentAddress != null) {
      String translatedAddress = MultilingualService.translatePlaceDescription(
        _currentAddress!,
      );
      welcome += "${MultilingualService.t('you_are_at')} $translatedAddress. ";
    }

    if (_savedPlaces.isNotEmpty) {
      welcome +=
          "${MultilingualService.t('press_select_to_search')}, ${MultilingualService.t('or')} ${MultilingualService.t('press_next_for_saved')}";
    } else {
      welcome += MultilingualService.t('press_select_to_search');
    }

    await _queueSpeech(welcome);
  }

  // ==================== BUTTON PRESS HANDLING ====================
  void _handleButtonPress(ButtonType buttonType) async {
    await wifiService.vibrateShort();

    switch (_currentState) {
      case AppState.idle:
        if (buttonType == ButtonType.select) {
          await _startAdvancedVoiceSearch();
        } else if (buttonType == ButtonType.next && _savedPlaces.isNotEmpty) {
          await _showSavedPlaces();
        }
        break;

      case AppState.listening:
        if (buttonType == ButtonType.select) {
          await speechService.stopListening();
          await _queueSpeech("Search cancelled.", priority: true);
          _currentState = AppState.idle;
          notifyListeners();
        }
        break;

      case AppState.processing:
        // Cannot interrupt processing
        break;

      case AppState.browsingSavedPlaces:
        if (buttonType == ButtonType.next) {
          await _navigateToNextSavedPlace();
        } else if (buttonType == ButtonType.previous) {
          await _navigateToPreviousSavedPlace();
        } else if (buttonType == ButtonType.select) {
          await _selectCurrentSavedPlace();
        }
        break;

      case AppState.browsingResults:
        if (buttonType == ButtonType.next) {
          await _navigateToNextResult();
        } else if (buttonType == ButtonType.previous) {
          await _navigateToPreviousResult();
        } else if (buttonType == ButtonType.select) {
          await _selectCurrentResult();
        }
        break;

      case AppState.navigating:
        if (buttonType == ButtonType.select) {
          await _stopNavigation();
        } else if (buttonType == ButtonType.next) {
          await _announceNavigationStatus();
        } else if (buttonType == ButtonType.previous) {
          await _announceCurrentStep();
        }
        break;
    }
  }

  // ==================== SAVED PLACES MANAGEMENT ====================
  Future<void> _showSavedPlaces() async {
    if (_savedPlaces.isEmpty) {
      await _queueSpeech("No saved places yet.", priority: true);
      return;
    }

    _currentState = AppState.browsingSavedPlaces;
    _currentSavedPlaceIndex = 0;
    notifyListeners();

    await _announceSavedPlace();
  }

  Future<void> _navigateToNextSavedPlace() async {
    if (_savedPlaces.isEmpty) return;

    _currentSavedPlaceIndex =
        (_currentSavedPlaceIndex + 1) % _savedPlaces.length;
    await _announceSavedPlace();
    notifyListeners();
  }

  Future<void> _navigateToPreviousSavedPlace() async {
    if (_savedPlaces.isEmpty) return;

    _currentSavedPlaceIndex =
        (_currentSavedPlaceIndex - 1 + _savedPlaces.length) %
        _savedPlaces.length;
    await _announceSavedPlace();
    notifyListeners();
  }

  Future<void> _announceSavedPlace() async {
    if (_savedPlaces.isEmpty) return;

    final place = _savedPlaces[_currentSavedPlaceIndex];
    String translatedName = MultilingualService.translatePlaceName(place.name);
    String translatedAddress = MultilingualService.translatePlaceDescription(
      place.address,
    );

    String announcement =
        "${MultilingualService.t('saved_place')} ${_currentSavedPlaceIndex + 1} ${MultilingualService.t('of')} ${_savedPlaces.length}: $translatedName";

    if (translatedAddress.isNotEmpty) {
      announcement +=
          ", ${MultilingualService.t('located_at')} $translatedAddress";
    }

    announcement +=
        ". ${MultilingualService.t('press_select_to_navigate')}, ${MultilingualService.t('or')} ${MultilingualService.t('use_next_previous_browse')}.";

    await _queueSpeech(announcement, priority: true);
  }

  Future<void> _selectCurrentSavedPlace() async {
    if (_savedPlaces.isEmpty) return;

    final savedPlace = _savedPlaces[_currentSavedPlaceIndex];

    await _queueSpeech(
      "Navigating to ${savedPlace.name}. Getting directions.",
      priority: true,
    );

    try {
      final destinationLatLng = LatLng(
        savedPlace.latitude,
        savedPlace.longitude,
      );

      _routeInfo = await mapsApiService.getDirections(
        _currentPosition!,
        destinationLatLng,
      );

      _selectedDestination = PredictedPlace(
        placeId: savedPlace.placeId ?? "",
        mainText: savedPlace.name,
        secondaryText: savedPlace.address,
      );

      _updateDestinationMarker(destinationLatLng, savedPlace.name);
      _drawRoute(_routeInfo!.polylinePoints);
      _moveCameraToRoute();

      String navAnnouncement =
          "Starting navigation to ${savedPlace.name}. Distance: ${_routeInfo!.distance}. Time: ${_routeInfo!.duration}. ${_getFirstInstruction()}";
      await _queueSpeech(navAnnouncement);

      _startNavigation();
    } catch (e) {
      print("Saved place navigation error: $e");
      await _queueSpeech(
        "Failed to get directions. Please try again.",
        priority: true,
      );
      _currentState = AppState.idle;
    }

    notifyListeners();
  }

  Future<void> saveCurrentDestination() async {
    if (_selectedDestination == null || _currentPosition == null) {
      await _queueSpeech("No destination to save.", priority: true);
      return;
    }

    try {
      final placeDetails = await mapsApiService.getPlaceDetails(
        _selectedDestination!.placeId,
      );

      final savedPlace = SavedPlace(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _selectedDestination!.mainText,
        address: _selectedDestination!.secondaryText,
        latitude: placeDetails['lat'],
        longitude: placeDetails['lng'],
        placeId: _selectedDestination!.placeId,
      );

      await savedPlacesService.savePlace(savedPlace);
      _savedPlaces = await savedPlacesService.getSavedPlaces();

      await _queueSpeech(
        "${savedPlace.name} saved successfully.",
        priority: true,
      );
      notifyListeners();
    } catch (e) {
      print("Save place error: $e");
      await _queueSpeech("Failed to save place.", priority: true);
    }
  }

  Future<void> deleteSavedPlace(String id) async {
    await savedPlacesService.deletePlace(id);
    _savedPlaces = await savedPlacesService.getSavedPlaces();
    notifyListeners();
  }

  // ==================== VOICE SEARCH ====================
  Future<void> _startAdvancedVoiceSearch() async {
    _currentState = AppState.listening;
    notifyListeners();

    await _queueSpeech("Listening.", priority: true);
    await Future.delayed(const Duration(milliseconds: 500));

    await speechService.startListening(
      timeout: const Duration(seconds: 12),
      onResult: (recognizedText) async {
        await _processAdvancedSearch(recognizedText);
      },
    );
  }

  Future<void> _processAdvancedSearch(String userInput) async {
    await aiSearchService.enhanceSearchQuery(
      userInput,
      _currentPosition!,
      _currentAddress,
      MultilingualService.currentLanguage,
    );

    if (userInput.isEmpty) {
      await _queueSpeech(
        "I didn't catch that. Please try again.",
        priority: true,
      );
      _currentState = AppState.idle;
      notifyListeners();
      return;
    }

    _currentState = AppState.processing;
    notifyListeners();

    if (userInput.toLowerCase().contains('help')) {
      await _provideHelp();
      _currentState = AppState.idle;
      notifyListeners();
      return;
    }

    await _queueSpeech("Searching for $userInput.", priority: true);

    try {
      String enhancedQuery = await aiAssistant.enhanceSearchQuery(
        userInput,
        _currentPosition!,
        _currentAddress,
      );

      _searchResults = await mapsApiService.searchPlacesAdvanced(
        enhancedQuery,
        _currentPosition!,
      );

      if (_searchResults.isEmpty) {
        List<String> alternatives = await aiAssistant.suggestAlternativeQueries(
          userInput,
        );
        for (String alt in alternatives) {
          _searchResults = await mapsApiService.searchPlacesAdvanced(
            alt,
            _currentPosition!,
          );
          if (_searchResults.isNotEmpty) break;
        }
      }

      if (_searchResults.isEmpty) {
        await _queueSpeech(
          "Sorry, no results found for $userInput. Try being more specific.",
          priority: true,
        );
        _currentState = AppState.idle;
      } else {
        _currentResultIndex = 0;
        _currentState = AppState.browsingResults;

        for (var place in _searchResults) {
          place.distance = await _calculateDistance(place);
        }

        _searchResults.sort(
          (a, b) => (a.distance ?? double.infinity).compareTo(
            b.distance ?? double.infinity,
          ),
        );

        String announcement = await _getSearchResultsAnnouncement();
        await _queueSpeech(announcement, priority: true);

        if (_searchResults.length == 1) {
          await Future.delayed(const Duration(seconds: 2));
          await _selectCurrentResult();
        }
      }
    } catch (e) {
      print("Search error: $e");
      await _queueSpeech("Search failed. Please try again.", priority: true);
      _currentState = AppState.idle;
    }

    notifyListeners();
  }

  Future<double?> _calculateDistance(PredictedPlace place) async {
    try {
      final details = await mapsApiService.getPlaceDetails(place.placeId);
      return Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        details['lat'],
        details['lng'],
      );
    } catch (e) {
      return null;
    }
  }

  // ==================== SEARCH RESULTS BROWSING ====================
  Future<String> _getSearchResultsAnnouncement() async {
    final current = _searchResults[_currentResultIndex];
    String distanceText = current.distance != null
        ? MultilingualService.formatDistance(current.distance!)
        : "";

    String translatedMain = MultilingualService.translatePlaceName(
      current.mainText,
    );
    String translatedSecondary = MultilingualService.translatePlaceDescription(
      current.secondaryText,
    );

    if (_searchResults.length == 1) {
      String announcement = "${MultilingualService.t('found')} $translatedMain";
      if (distanceText.isNotEmpty) {
        announcement += ", $distanceText ${MultilingualService.t('away')}";
      }
      if (translatedSecondary.isNotEmpty) {
        announcement +=
            ", ${MultilingualService.t('located_at')} $translatedSecondary";
      }
      announcement += ". ${MultilingualService.t('press_select_to_navigate')}";
      return announcement;
    } else {
      String announcement =
          "${MultilingualService.t('found')} ${_searchResults.length} ${MultilingualService.t('places')}. ";
      announcement +=
          "${MultilingualService.t('result')} 1 ${MultilingualService.t('of')} ${_searchResults.length}: $translatedMain";
      if (distanceText.isNotEmpty) {
        announcement += ", $distanceText ${MultilingualService.t('away')}";
      }
      announcement += ". ${MultilingualService.t('use_next_previous_browse')}";
      return announcement;
    }
  }

  Future<void> _navigateToNextResult() async {
    if (_searchResults.isEmpty) return;
    _currentResultIndex = (_currentResultIndex + 1) % _searchResults.length;
    await _announceCurrentResult();
    notifyListeners();
  }

  Future<void> _navigateToPreviousResult() async {
    if (_searchResults.isEmpty) return;
    _currentResultIndex =
        (_currentResultIndex - 1 + _searchResults.length) %
        _searchResults.length;
    await _announceCurrentResult();
    notifyListeners();
  }

  Future<void> _announceCurrentResult() async {
    if (_searchResults.isEmpty) return;

    final current = _searchResults[_currentResultIndex];
    String distanceText = current.distance != null
        ? MultilingualService.formatDistance(current.distance!)
        : "";

    String translatedMain = MultilingualService.translatePlaceName(
      current.mainText,
    );
    String translatedSecondary = MultilingualService.translatePlaceDescription(
      current.secondaryText,
    );

    String announcement =
        "${MultilingualService.t('option')} ${_currentResultIndex + 1} ${MultilingualService.t('of')} ${_searchResults.length}: $translatedMain";

    if (distanceText.isNotEmpty) {
      announcement += ", $distanceText ${MultilingualService.t('away')}";
    }

    if (translatedSecondary.isNotEmpty) {
      announcement +=
          ", ${MultilingualService.t('located_at')} $translatedSecondary";
    }

    announcement += ".";
    await _queueSpeech(announcement, priority: true);
  }

  Future<void> _selectCurrentResult() async {
    if (_searchResults.isEmpty) return;

    _selectedDestination = _searchResults[_currentResultIndex];
    String translatedDestination = MultilingualService.translatePlaceName(
      _selectedDestination!.mainText,
    );

    try {
      await _queueSpeech(
        "${MultilingualService.t('getting_directions')}, ${MultilingualService.t('please_wait')}.",
        priority: true,
      );

      final placeDetails = await mapsApiService.getPlaceDetails(
        _selectedDestination!.placeId,
      );
      final destinationLatLng = LatLng(
        placeDetails['lat'],
        placeDetails['lng'],
      );

      _routeInfo = await mapsApiService.getDirections(
        _currentPosition!,
        destinationLatLng,
      );

      _updateDestinationMarker(destinationLatLng, translatedDestination);
      _drawRoute(_routeInfo!.polylinePoints);
      _moveCameraToRoute();

      String firstInstruction = _getFirstInstruction();
      String translatedInstruction = _translateInstruction(firstInstruction);

      String navAnnouncement = MultilingualService.formatNavigationStart(
        translatedDestination,
        _routeInfo!.distance,
        _routeInfo!.duration,
      );
      navAnnouncement += " $translatedInstruction";

      await _queueSpeech(navAnnouncement);
      _startNavigation();
    } catch (e) {
      print("Navigation error: $e");
      await _queueSpeech(
        "${MultilingualService.t('failed_to_get_directions')}. ${MultilingualService.t('try_again')}",
        priority: true,
      );
      _currentState = AppState.idle;
    }

    notifyListeners();
  }

  // ==================== NAVIGATION ====================
  String _translateInstruction(String instruction) {
    instruction = instruction
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .trim();

    String translated = instruction;

    if (instruction.toLowerCase().contains('turn left')) {
      translated = translated.replaceAllMapped(
        RegExp(r'turn left', caseSensitive: false),
        (match) => MultilingualService.t('turn_left'),
      );
    }
    if (instruction.toLowerCase().contains('turn right')) {
      translated = translated.replaceAllMapped(
        RegExp(r'turn right', caseSensitive: false),
        (match) => MultilingualService.t('turn_right'),
      );
    }
    if (instruction.toLowerCase().contains('go straight') ||
        instruction.toLowerCase().contains('continue straight')) {
      translated = translated.replaceAllMapped(
        RegExp(r'(go|continue) straight', caseSensitive: false),
        (match) => MultilingualService.t('go_straight'),
      );
    }
    if (instruction.toLowerCase().contains('u-turn')) {
      translated = translated.replaceAllMapped(
        RegExp(r'u-turn', caseSensitive: false),
        (match) => MultilingualService.t('u_turn'),
      );
    }

    translated = MultilingualService.translatePlaceDescription(translated);

    return translated;
  }

  String _getFirstInstruction() {
    if (_routeInfo!.steps.isEmpty) return "";
    var firstStep = _routeInfo!.steps[0];
    String instruction = firstStep['html_instructions'] ?? "";
    instruction = instruction
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ');
    return instruction;
  }

  void _startNavigation() {
    _currentState = AppState.navigating;
    _currentStepIndex = 0;
    _routePoints = _routeInfo!.polylinePoints;
    _lastAnnouncedDistance = 0;
    _lastDistanceAnnouncement = null;
    _offRoute = false;

    _navigationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateNavigation();
    });

    notifyListeners();
  }

  void _updateNavigation() async {
    if (_currentPosition == null || _routeInfo == null) return;

    int closestPointIndex = navigationService.findClosestPointOnRoute(
      _currentPosition!,
      _routePoints,
    );

    double distanceToRoute = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _routePoints[closestPointIndex].latitude,
      _routePoints[closestPointIndex].longitude,
    );

    if (distanceToRoute > 50 && !_offRoute) {
      _offRoute = true;
      await _queueSpeech(MultilingualService.t('off_route'), priority: true);
      await _recalculateRoute();
      return;
    }

    _currentStepIndex = closestPointIndex;

    // Announce turns with translation
    final now = DateTime.now();
    if (_lastTurnAnnouncement == null ||
        now.difference(_lastTurnAnnouncement!) > const Duration(seconds: 20)) {
      final turnInfo = navigationService.detectUpcomingTurn(
        _routePoints,
        closestPointIndex,
        lookAheadPoints: 15,
      );

      if (turnInfo != null && turnInfo['distance'] != null) {
        String distanceStr = turnInfo['distance'].toString();
        String direction = turnInfo['direction'].toString();

        String announcement = MultilingualService.formatTurnInstruction(
          direction,
          distanceStr,
        );

        await _queueSpeech(announcement);
        _lastTurnAnnouncement = now;

        if (direction.toLowerCase().contains('left')) {
          await wifiService.vibrateLeftTurn();
        } else if (direction.toLowerCase().contains('right')) {
          await wifiService.vibrateRightTurn();
        }
      }
    }

    // Announce distance with translation
    final distanceToDestination = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _routePoints.last.latitude,
      _routePoints.last.longitude,
    );

    if (_lastDistanceAnnouncement == null ||
        now.difference(_lastDistanceAnnouncement!) >
            const Duration(minutes: 2) ||
        (_lastAnnouncedDistance - distanceToDestination) > 500) {
      String distanceText = MultilingualService.formatDistance(
        distanceToDestination,
      );
      await _queueSpeech(
        "$distanceText ${MultilingualService.t('remaining')}.",
      );
      _lastAnnouncedDistance = distanceToDestination;
      _lastDistanceAnnouncement = now;
    }

    // Check for arrival
    if (distanceToDestination < 30) {
      await _completeNavigation();
    }
  }

  Future<void> _recalculateRoute() async {
    if (_selectedDestination == null || _currentPosition == null) return;

    try {
      final placeDetails = await mapsApiService.getPlaceDetails(
        _selectedDestination!.placeId,
      );
      final destinationLatLng = LatLng(
        placeDetails['lat'],
        placeDetails['lng'],
      );

      _routeInfo = await mapsApiService.getDirections(
        _currentPosition!,
        destinationLatLng,
      );
      _routePoints = _routeInfo!.polylinePoints;
      _drawRoute(_routePoints);
      _offRoute = false;

      await _queueSpeech("Route updated. Continue following directions.");
    } catch (e) {
      print("Recalculation error: $e");
    }
  }

  Future<void> _announceNavigationStatus() async {
    if (_routeInfo == null || _currentPosition == null) return;

    final distanceToDestination = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _routePoints.last.latitude,
      _routePoints.last.longitude,
    );

    String distanceText = MultilingualService.formatDistance(
      distanceToDestination,
    );
    String translatedDestination = MultilingualService.translatePlaceName(
      _selectedDestination!.mainText,
    );

    await _queueSpeech(
      "${MultilingualService.t('you_are_at')} $distanceText ${MultilingualService.t('away')} ${MultilingualService.t('from')} $translatedDestination.",
      priority: true,
    );
  }

  Future<void> _announceCurrentStep() async {
    if (_routeInfo == null || _currentStepIndex >= _routeInfo!.steps.length)
      return;

    var currentStep = _routeInfo!.steps[_currentStepIndex];
    String instruction = currentStep['html_instructions'] ?? "";
    instruction = instruction
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ');

    await _queueSpeech(instruction, priority: true);
  }

  void _checkNavigationProgress() {
    _updateNavigation();
  }

  Future<void> _completeNavigation() async {
    _stopNavigationTimer();

    String translatedDestination = MultilingualService.translatePlaceName(
      _selectedDestination!.mainText,
    );
    String announcement = MultilingualService.formatArrivalAnnouncement(
      translatedDestination,
    );

    await _queueSpeech(announcement, priority: true);
    await wifiService.vibrateDestinationReached();

    _currentState = AppState.idle;
    _selectedDestination = null;
    _routeInfo = null;
    _searchResults.clear();
    _polylines.clear();
    _markers.removeWhere((m) => m.markerId.value == 'destination');

    await Future.delayed(const Duration(seconds: 3));
    await _announceWelcomeWithContext();

    notifyListeners();
  }

  Future<void> _stopNavigation() async {
    _stopNavigationTimer();

    await _queueSpeech(
      MultilingualService.t('navigation_stopped'),
      priority: true,
    );
    await wifiService.vibrateShort();

    _currentState = AppState.idle;
    _selectedDestination = null;
    _routeInfo = null;
    _searchResults.clear();
    _polylines.clear();
    _markers.removeWhere((m) => m.markerId.value == 'destination');

    await Future.delayed(const Duration(seconds: 2));
    await _announceWelcomeWithContext();

    notifyListeners();
  }

  void _stopNavigationTimer() {
    _navigationTimer?.cancel();
    _navigationTimer = null;
  }

  // ==================== HELPER METHODS ====================
  Future<void> _provideHelp() async {
    String help = MultilingualService.t('search_examples');
    help +=
        " ${MultilingualService.t('select_stop_next_status_prev_instruction')}.";
    await _queueSpeech(help, priority: true);
  }

  void _updateCurrentLocationMarker() {
    if (_currentPosition == null) return;

    _markers.removeWhere((m) => m.markerId.value == 'current');
    _markers.add(
      Marker(
        markerId: const MarkerId('current'),
        position: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );
  }

  void _updateDestinationMarker(LatLng position, String title) {
    _markers.removeWhere((m) => m.markerId.value == 'destination');
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: position,
        infoWindow: InfoWindow(title: title),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  void _drawRoute(List<LatLng> points) {
    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: Colors.blue,
        width: 6,
        patterns: [PatternItem.dash(30), PatternItem.gap(20)],
      ),
    );
  }

  void _moveCameraToRoute() {
    if (_mapController == null || _routePoints.isEmpty) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100,
      ),
    );
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  void dispose() {
    _stopNavigationTimer();
    wifiService.dispose();
    speechService.dispose();
    locationService.dispose();
    super.dispose();
  }
}

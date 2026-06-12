import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, hindi }

class MultilingualService {
  static AppLanguage _currentLanguage = AppLanguage.english;
  static const String _languageKey = 'app_language';

  // Get current language
  static AppLanguage get currentLanguage => _currentLanguage;

  // Get language code for TTS
  static String get languageCode {
    switch (_currentLanguage) {
      case AppLanguage.english:
        return 'en-US';
      case AppLanguage.hindi:
        return 'hi-IN';
    }
  }

  // Get language code for speech recognition
  static String get speechRecognitionCode {
    switch (_currentLanguage) {
      case AppLanguage.english:
        return 'en_US';
      case AppLanguage.hindi:
        return 'hi_IN';
    }
  }

  // Initialize and load saved language
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);

    if (savedLanguage == 'hindi') {
      _currentLanguage = AppLanguage.hindi;
    } else {
      _currentLanguage = AppLanguage.english;
    }

    print('Loaded language: ${_currentLanguage.toString()}');
  }

  // Change language
  static Future<void> setLanguage(AppLanguage language) async {
    _currentLanguage = language;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _languageKey,
      language == AppLanguage.hindi ? 'hindi' : 'english',
    );

    print('Language changed to: ${language.toString()}');
  }

  // Complete translations map with all common place types
  static final Map<String, Map<AppLanguage, String>> _translations = {
    // App & Welcome
    'app_name': {
      AppLanguage.english: 'Smart Blind Stick',
      AppLanguage.hindi: 'स्मार्ट ब्लाइंड स्टिक',
    },
    'welcome': {
      AppLanguage.english: 'Smart Blind Stick Ready',
      AppLanguage.hindi: 'स्मार्ट ब्लाइंड स्टिक तैयार',
    },
    'initializing': {
      AppLanguage.english: 'Initializing',
      AppLanguage.hindi: 'शुरू हो रहा है',
    },
    'welcome_message': {
      AppLanguage.english: 'Welcome!',
      AppLanguage.hindi: 'स्वागत है!',
    },
    'choose_language': {
      AppLanguage.english: 'Choose your preferred language',
      AppLanguage.hindi: 'अपनी भाषा चुनें',
    },
    'select_language': {
      AppLanguage.english: 'Select Language',
      AppLanguage.hindi: 'भाषा चुनें',
    },
    'continue': {
      AppLanguage.english: 'Continue',
      AppLanguage.hindi: 'जारी रखें',
    },

    // Connection Status
    'you_are_at': {
      AppLanguage.english: 'You are at',
      AppLanguage.hindi: 'आप यहाँ हैं',
    },
    'your_current_location': {
      AppLanguage.english: 'Your current location',
      AppLanguage.hindi: 'आपका वर्तमान स्थान',
    },
    'connecting': {
      AppLanguage.english: 'Connecting to stick',
      AppLanguage.hindi: 'स्टिक से जुड़ रहे हैं',
    },
    'connected': {
      AppLanguage.english: 'Connected to Smart Blind Stick',
      AppLanguage.hindi: 'स्मार्ट स्टिक से जुड़ा',
    },
    'disconnected': {
      AppLanguage.english: 'Disconnected. Attempting to reconnect',
      AppLanguage.hindi: 'डिस्कनेक्ट हो गया। फिर से कनेक्ट करने की कोशिश',
    },
    'not_connected': {
      AppLanguage.english: 'Not connected',
      AppLanguage.hindi: 'कनेक्ट नहीं है',
    },

    // Voice Search & Instructions
    'voice_search': {
      AppLanguage.english: 'Voice Search',
      AppLanguage.hindi: 'वॉइस सर्च',
    },
    'listening': {
      AppLanguage.english: 'Listening',
      AppLanguage.hindi: 'सुन रहे हैं',
    },
    'say_destination_clearly': {
      AppLanguage.english: 'Say your destination clearly',
      AppLanguage.hindi: 'अपना गंतव्य स्पष्ट रूप से बोलें',
    },
    'search_examples': {
      AppLanguage.english:
          'For example: nearest hospital, coffee shop on main street, or a place name',
      AppLanguage.hindi:
          'उदाहरण: नज़दीकी अस्पताल, मुख्य सड़क पर कॉफ़ी की दुकान, या किसी स्थान का नाम',
    },
    'searching_for': {
      AppLanguage.english: 'Searching for',
      AppLanguage.hindi: 'खोज रहे हैं',
    },
    'searching': {
      AppLanguage.english: 'Searching',
      AppLanguage.hindi: 'खोज रहे हैं',
    },
    'please_wait': {
      AppLanguage.english: 'Please wait',
      AppLanguage.hindi: 'कृपया प्रतीक्षा करें',
    },
    'processing': {
      AppLanguage.english: 'Processing',
      AppLanguage.hindi: 'प्रोसेस हो रहा है',
    },
    'search_cancelled': {
      AppLanguage.english: 'Search cancelled',
      AppLanguage.hindi: 'खोज रद्द की गई',
    },

    // Search Results
    'no_results': {
      AppLanguage.english: 'Sorry, no results found. Try being more specific',
      AppLanguage.hindi:
          'क्षमा करें, कोई परिणाम नहीं मिला। अधिक विशिष्ट होने का प्रयास करें',
    },
    'found': {AppLanguage.english: 'Found', AppLanguage.hindi: 'मिला'},
    'places': {AppLanguage.english: 'places', AppLanguage.hindi: 'स्थान'},
    'result': {AppLanguage.english: 'Result', AppLanguage.hindi: 'परिणाम'},
    'of': {AppLanguage.english: 'of', AppLanguage.hindi: 'में से'},
    'away': {AppLanguage.english: 'away', AppLanguage.hindi: 'दूर'},
    'option': {AppLanguage.english: 'Option', AppLanguage.hindi: 'विकल्प'},
    'near_you': {
      AppLanguage.english: 'near you',
      AppLanguage.hindi: 'आपके पास',
    },
    'nearby': {AppLanguage.english: 'nearby', AppLanguage.hindi: 'नज़दीकी'},
    'closest': {AppLanguage.english: 'closest', AppLanguage.hindi: 'सबसे करीब'},
    'located_at': {
      AppLanguage.english: 'located at',
      AppLanguage.hindi: 'स्थित है',
    },

    // Navigation
    'getting_directions': {
      AppLanguage.english: 'Getting directions, please wait',
      AppLanguage.hindi:
          'दिशा-निर्देश प्राप्त कर रहे हैं, कृपया प्रतीक्षा करें',
    },
    'starting_navigation': {
      AppLanguage.english: 'Starting navigation to',
      AppLanguage.hindi: 'नेविगेशन शुरू कर रहे हैं',
    },
    'navigating_to': {
      AppLanguage.english: 'Navigating to',
      AppLanguage.hindi: 'नेविगेट कर रहे हैं',
    },
    'distance': {AppLanguage.english: 'Distance', AppLanguage.hindi: 'दूरी'},
    'time': {AppLanguage.english: 'Time', AppLanguage.hindi: 'समय'},
    'duration': {AppLanguage.english: 'Duration', AppLanguage.hindi: 'अवधि'},
    'kilometers': {
      AppLanguage.english: 'kilometers',
      AppLanguage.hindi: 'किलोमीटर',
    },
    'km': {AppLanguage.english: 'km', AppLanguage.hindi: 'किमी'},
    'meters': {AppLanguage.english: 'meters', AppLanguage.hindi: 'मीटर'},
    'm': {AppLanguage.english: 'm', AppLanguage.hindi: 'मी'},
    'remaining': {AppLanguage.english: 'remaining', AppLanguage.hindi: 'शेष'},
    'minutes': {AppLanguage.english: 'minutes', AppLanguage.hindi: 'मिनट'},
    'hours': {AppLanguage.english: 'hours', AppLanguage.hindi: 'घंटे'},

    // Turn Instructions
    'turn_left': {
      AppLanguage.english: 'Turn left',
      AppLanguage.hindi: 'बाएं मुड़ें',
    },
    'turn_right': {
      AppLanguage.english: 'Turn right',
      AppLanguage.hindi: 'दाएं मुड़ें',
    },
    'go_straight': {
      AppLanguage.english: 'Go straight',
      AppLanguage.hindi: 'सीधे जाएं',
    },
    'slight_left': {
      AppLanguage.english: 'Slight left',
      AppLanguage.hindi: 'थोड़ा बाएं',
    },
    'slight_right': {
      AppLanguage.english: 'Slight right',
      AppLanguage.hindi: 'थोड़ा दाएं',
    },
    'sharp_left': {
      AppLanguage.english: 'Sharp left',
      AppLanguage.hindi: 'तेज़ बाएं मोड़',
    },
    'sharp_right': {
      AppLanguage.english: 'Sharp right',
      AppLanguage.hindi: 'तेज़ दाएं मोड़',
    },
    'u_turn': {
      AppLanguage.english: 'Make a U-turn',
      AppLanguage.hindi: 'यू-टर्न लें',
    },
    'in': {AppLanguage.english: 'In', AppLanguage.hindi: ''},
    'ahead': {AppLanguage.english: 'ahead', AppLanguage.hindi: 'आगे'},
    'continue_for': {
      AppLanguage.english: 'Continue for',
      AppLanguage.hindi: 'जारी रखें',
    },
    'then': {AppLanguage.english: 'then', AppLanguage.hindi: 'फिर'},
    'at_roundabout': {
      AppLanguage.english: 'At the roundabout',
      AppLanguage.hindi: 'गोल चक्कर पर',
    },
    'take_exit': {
      AppLanguage.english: 'take exit',
      AppLanguage.hindi: 'निकास लें',
    },

    // Arrival & Completion
    'you_arrived': {
      AppLanguage.english: 'You have arrived at',
      AppLanguage.hindi: 'आप पहुंच गए हैं',
    },
    'destination_reached': {
      AppLanguage.english: 'Destination reached',
      AppLanguage.hindi: 'गंतव्य पर पहुंच गए',
    },
    'navigation_complete': {
      AppLanguage.english: 'Navigation complete',
      AppLanguage.hindi: 'नेविगेशन पूर्ण',
    },
    'navigation_stopped': {
      AppLanguage.english: 'Navigation stopped',
      AppLanguage.hindi: 'नेविगेशन रोका गया',
    },
    'arriving_soon': {
      AppLanguage.english: 'Arriving soon',
      AppLanguage.hindi: 'जल्द पहुंच रहे हैं',
    },
    'almost_there': {
      AppLanguage.english: 'Almost there',
      AppLanguage.hindi: 'लगभग पहुंच गए',
    },

    // Rerouting
    'off_route': {
      AppLanguage.english: 'You may be off route. Recalculating',
      AppLanguage.hindi: 'आप रास्ते से भटक गए हैं। फिर से गणना कर रहे हैं',
    },
    'route_updated': {
      AppLanguage.english: 'Route updated. Continue following directions',
      AppLanguage.hindi: 'मार्ग अपडेट हुआ। निर्देशों का पालन जारी रखें',
    },
    'recalculating': {
      AppLanguage.english: 'Recalculating route',
      AppLanguage.hindi: 'मार्ग की पुनर्गणना कर रहे हैं',
    },

    // Saved Places
    'saved_places': {
      AppLanguage.english: 'Saved Places',
      AppLanguage.hindi: 'सहेजे गए स्थान',
    },
    'no_saved_places': {
      AppLanguage.english: 'No saved places yet',
      AppLanguage.hindi: 'अभी तक कोई स्थान सहेजा नहीं गया',
    },
    'saved_place': {
      AppLanguage.english: 'Saved place',
      AppLanguage.hindi: 'सहेजा गया स्थान',
    },
    'saved': {AppLanguage.english: 'Saved', AppLanguage.hindi: 'सहेजा गया'},
    'at': {AppLanguage.english: 'at', AppLanguage.hindi: ''},
    'saved_successfully': {
      AppLanguage.english: 'saved successfully',
      AppLanguage.hindi: 'सफलतापूर्वक सहेजा गया',
    },
    'failed_to_save': {
      AppLanguage.english: 'Failed to save place',
      AppLanguage.hindi: 'स्थान सहेजने में विफल',
    },
    'place_saved': {
      AppLanguage.english: 'Place saved',
      AppLanguage.hindi: 'स्थान सहेजा गया',
    },
    'add_place': {
      AppLanguage.english: 'Add Place',
      AppLanguage.hindi: 'स्थान जोड़ें',
    },
    'delete': {AppLanguage.english: 'Delete', AppLanguage.hindi: 'हटाएं'},
    'deleted': {AppLanguage.english: 'deleted', AppLanguage.hindi: 'हटाया गया'},
    'edit': {AppLanguage.english: 'Edit', AppLanguage.hindi: 'संपादित करें'},

    // Place Types - Common Places
    'hospital': {AppLanguage.english: 'Hospital', AppLanguage.hindi: 'अस्पताल'},
    'pharmacy': {AppLanguage.english: 'Pharmacy', AppLanguage.hindi: 'दवाखाना'},
    'medical_store': {
      AppLanguage.english: 'Medical Store',
      AppLanguage.hindi: 'दवाई की दुकान',
    },
    'clinic': {AppLanguage.english: 'Clinic', AppLanguage.hindi: 'क्लिनिक'},
    'doctor': {AppLanguage.english: 'Doctor', AppLanguage.hindi: 'डॉक्टर'},
    'restaurant': {
      AppLanguage.english: 'Restaurant',
      AppLanguage.hindi: 'रेस्तरां',
    },
    'cafe': {AppLanguage.english: 'Cafe', AppLanguage.hindi: 'कैफे'},
    'coffee_shop': {
      AppLanguage.english: 'Coffee Shop',
      AppLanguage.hindi: 'कॉफी की दुकान',
    },
    'tea_shop': {
      AppLanguage.english: 'Tea Shop',
      AppLanguage.hindi: 'चाय की दुकान',
    },
    'hotel': {AppLanguage.english: 'Hotel', AppLanguage.hindi: 'होटल'},
    'bank': {AppLanguage.english: 'Bank', AppLanguage.hindi: 'बैंक'},
    'atm': {AppLanguage.english: 'ATM', AppLanguage.hindi: 'एटीएम'},
    'police_station': {
      AppLanguage.english: 'Police Station',
      AppLanguage.hindi: 'पुलिस थाना',
    },
    'fire_station': {
      AppLanguage.english: 'Fire Station',
      AppLanguage.hindi: 'फायर स्टेशन',
    },
    'park': {AppLanguage.english: 'Park', AppLanguage.hindi: 'पार्क'},
    'garden': {AppLanguage.english: 'Garden', AppLanguage.hindi: 'बाग'},
    'temple': {AppLanguage.english: 'Temple', AppLanguage.hindi: 'मंदिर'},
    'mosque': {AppLanguage.english: 'Mosque', AppLanguage.hindi: 'मस्जिद'},
    'church': {AppLanguage.english: 'Church', AppLanguage.hindi: 'गिरजाघर'},
    'gurudwara': {
      AppLanguage.english: 'Gurudwara',
      AppLanguage.hindi: 'गुरुद्वारा',
    },
    'station': {AppLanguage.english: 'Station', AppLanguage.hindi: 'स्टेशन'},
    'railway_station': {
      AppLanguage.english: 'Railway Station',
      AppLanguage.hindi: 'रेलवे स्टेशन',
    },
    'bus_stop': {
      AppLanguage.english: 'Bus Stop',
      AppLanguage.hindi: 'बस स्टॉप',
    },
    'metro_station': {
      AppLanguage.english: 'Metro Station',
      AppLanguage.hindi: 'मेट्रो स्टेशन',
    },
    'airport': {
      AppLanguage.english: 'Airport',
      AppLanguage.hindi: 'हवाई अड्डा',
    },
    'grocery_store': {
      AppLanguage.english: 'Grocery Store',
      AppLanguage.hindi: 'किराना स्टोर',
    },
    'supermarket': {
      AppLanguage.english: 'Supermarket',
      AppLanguage.hindi: 'सुपरमार्केट',
    },
    'mall': {AppLanguage.english: 'Mall', AppLanguage.hindi: 'मॉल'},
    'market': {AppLanguage.english: 'Market', AppLanguage.hindi: 'बाजार'},
    'shop': {AppLanguage.english: 'Shop', AppLanguage.hindi: 'दुकान'},
    'store': {AppLanguage.english: 'Store', AppLanguage.hindi: 'स्टोर'},
    'gas_station': {
      AppLanguage.english: 'Gas Station',
      AppLanguage.hindi: 'पेट्रोल पंप',
    },
    'petrol_pump': {
      AppLanguage.english: 'Petrol Pump',
      AppLanguage.hindi: 'पेट्रोल पंप',
    },
    'school': {AppLanguage.english: 'School', AppLanguage.hindi: 'स्कूल'},
    'college': {AppLanguage.english: 'College', AppLanguage.hindi: 'कॉलेज'},
    'university': {
      AppLanguage.english: 'University',
      AppLanguage.hindi: 'विश्वविद्यालय',
    },
    'library': {AppLanguage.english: 'Library', AppLanguage.hindi: 'पुस्तकालय'},
    'cinema': {AppLanguage.english: 'Cinema', AppLanguage.hindi: 'सिनेमा'},
    'theater': {AppLanguage.english: 'Theater', AppLanguage.hindi: 'थिएटर'},
    'gym': {AppLanguage.english: 'Gym', AppLanguage.hindi: 'जिम'},
    'salon': {AppLanguage.english: 'Salon', AppLanguage.hindi: 'सैलून'},
    'spa': {AppLanguage.english: 'Spa', AppLanguage.hindi: 'स्पा'},
    'post_office': {
      AppLanguage.english: 'Post Office',
      AppLanguage.hindi: 'डाकघर',
    },
    'government_office': {
      AppLanguage.english: 'Government Office',
      AppLanguage.hindi: 'सरकारी कार्यालय',
    },

    // Button Actions & Instructions
    'press_select_to_search': {
      AppLanguage.english: 'Press Select to search for a destination',
      AppLanguage.hindi: 'गंतव्य खोजने के लिए सेलेक्ट दबाएं',
    },
    'press_next_for_saved': {
      AppLanguage.english: 'Press Next to browse your saved places',
      AppLanguage.hindi:
          'अपने सहेजे गए स्थानों को ब्राउज़ करने के लिए नेक्स्ट दबाएं',
    },
    'press_select_to_navigate': {
      AppLanguage.english: 'Press Select to navigate',
      AppLanguage.hindi: 'नेविगेट करने के लिए सेलेक्ट दबाएं',
    },
    'use_next_previous_browse': {
      AppLanguage.english:
          'Use Next and Previous to browse, Select to navigate',
      AppLanguage.hindi:
          'ब्राउज़ करने के लिए नेक्स्ट और पिछला, नेविगेट करने के लिए सेलेक्ट',
    },
    'next': {AppLanguage.english: 'Next', AppLanguage.hindi: 'अगला'},
    'previous': {AppLanguage.english: 'Previous', AppLanguage.hindi: 'पिछला'},
    'select': {AppLanguage.english: 'Select', AppLanguage.hindi: 'चुनें'},
    'browse': {
      AppLanguage.english: 'Browse',
      AppLanguage.hindi: 'ब्राउज़ करें',
    },
    'navigate': {
      AppLanguage.english: 'Navigate',
      AppLanguage.hindi: 'नेविगेट करें',
    },
    'save': {AppLanguage.english: 'Save', AppLanguage.hindi: 'सहेजें'},
    'cancel': {AppLanguage.english: 'Cancel', AppLanguage.hindi: 'रद्द करें'},
    'stop': {AppLanguage.english: 'Stop', AppLanguage.hindi: 'रोकें'},
    'status': {AppLanguage.english: 'Status', AppLanguage.hindi: 'स्थिति'},
    'instruction': {
      AppLanguage.english: 'Instruction',
      AppLanguage.hindi: 'निर्देश',
    },
    'select_stop_next_status_prev_instruction': {
      AppLanguage.english:
          'Select: Stop • Next: Status • Previous: Instruction',
      AppLanguage.hindi: 'सेलेक्ट: रोकें • नेक्स्ट: स्थिति • पिछला: निर्देश',
    },
    'next_prev_browse_select_navigate': {
      AppLanguage.english: 'Next/Previous: Browse • Select: Navigate',
      AppLanguage.hindi: 'नेक्स्ट/पिछला: ब्राउज़ • सेलेक्ट: नेविगेट',
    },
    'double_tap_to_navigate': {
      AppLanguage.english: 'Double tap to navigate',
      AppLanguage.hindi: 'नेविगेट करने के लिए डबल टैप करें',
    },
    'press_button_to_start': {
      AppLanguage.english:
          'Press the Select button on your stick to start voice search',
      AppLanguage.hindi:
          'वॉइस सर्च शुरू करने के लिए अपनी स्टिक पर सेलेक्ट बटन दबाएं',
    },

    // Categories
    'home': {AppLanguage.english: 'Home', AppLanguage.hindi: 'घर'},
    'work': {AppLanguage.english: 'Work', AppLanguage.hindi: 'कार्यालय'},
    'favorite': {AppLanguage.english: 'Favorite', AppLanguage.hindi: 'पसंदीदा'},
    'other': {AppLanguage.english: 'Other', AppLanguage.hindi: 'अन्य'},
    'all': {AppLanguage.english: 'All', AppLanguage.hindi: 'सभी'},

    // Help & Settings
    'help': {AppLanguage.english: 'Help', AppLanguage.hindi: 'सहायता'},
    'how_to_use': {
      AppLanguage.english: 'How to Use',
      AppLanguage.hindi: 'उपयोग करने का तरीका',
    },
    'settings': {
      AppLanguage.english: 'Settings',
      AppLanguage.hindi: 'सेटिंग्स',
    },
    'language': {AppLanguage.english: 'Language', AppLanguage.hindi: 'भाषा'},
    'english': {AppLanguage.english: 'English', AppLanguage.hindi: 'अंग्रेज़ी'},
    'hindi': {AppLanguage.english: 'Hindi', AppLanguage.hindi: 'हिन्दी'},
    'language_set': {
      AppLanguage.english: 'Language set',
      AppLanguage.hindi: 'भाषा सेट की गई',
    },

    // Location & Map
    'my_location': {
      AppLanguage.english: 'My Location',
      AppLanguage.hindi: 'मेरा स्थान',
    },
    'current_location': {
      AppLanguage.english: 'Current location',
      AppLanguage.hindi: 'वर्तमान स्थान',
    },
    'unknown_location': {
      AppLanguage.english: 'Unknown location',
      AppLanguage.hindi: 'अज्ञात स्थान',
    },

    // Errors
    'error': {AppLanguage.english: 'Error', AppLanguage.hindi: 'त्रुटि'},
    'try_again': {
      AppLanguage.english: 'Please try again',
      AppLanguage.hindi: 'कृपया पुनः प्रयास करें',
    },
    'failed_to_get_directions': {
      AppLanguage.english: 'Failed to get directions',
      AppLanguage.hindi: 'दिशा-निर्देश प्राप्त करने में विफल',
    },
    'connection_error': {
      AppLanguage.english: 'Connection error',
      AppLanguage.hindi: 'कनेक्शन त्रुटि',
    },

    // Additional Common Terms
    'from': {AppLanguage.english: 'from', AppLanguage.hindi: 'से'},
    'or': {AppLanguage.english: 'or', AppLanguage.hindi: 'या'},
    'to': {AppLanguage.english: 'to', AppLanguage.hindi: 'तक'},
    'for': {AppLanguage.english: 'for', AppLanguage.hindi: 'के लिए'},
    'note': {AppLanguage.english: 'Note', AppLanguage.hindi: 'नोट'},
    'notes': {AppLanguage.english: 'Notes', AppLanguage.hindi: 'नोट्स'},
    'no_destination_to_save': {
      AppLanguage.english: 'No destination to save',
      AppLanguage.hindi: 'सहेजने के लिए कोई गंतव्य नहीं',
    },
    'search_error': {
      AppLanguage.english: 'Search failed',
      AppLanguage.hindi: 'खोज विफल रही',
    },
    'today': {AppLanguage.english: 'Today', AppLanguage.hindi: 'आज'},
    'yesterday': {AppLanguage.english: 'Yesterday', AppLanguage.hindi: 'कल'},
    'days_ago': {
      AppLanguage.english: 'days ago',
      AppLanguage.hindi: 'दिन पहले',
    },

    // More place types
    'tourist_attraction': {
      AppLanguage.english: 'Tourist Attraction',
      AppLanguage.hindi: 'पर्यटक स्थल',
    },
    'monument': {AppLanguage.english: 'Monument', AppLanguage.hindi: 'स्मारक'},
    'museum': {AppLanguage.english: 'Museum', AppLanguage.hindi: 'संग्रहालय'},
    'zoo': {AppLanguage.english: 'Zoo', AppLanguage.hindi: 'चिड़ियाघर'},
    'stadium': {AppLanguage.english: 'Stadium', AppLanguage.hindi: 'स्टेडियम'},
    'parking': {AppLanguage.english: 'Parking', AppLanguage.hindi: 'पार्किंग'},
    'toll_plaza': {
      AppLanguage.english: 'Toll Plaza',
      AppLanguage.hindi: 'टोल प्लाजा',
    },
    'bridge': {AppLanguage.english: 'Bridge', AppLanguage.hindi: 'पुल'},
    'flyover': {AppLanguage.english: 'Flyover', AppLanguage.hindi: 'फ्लाईओवर'},
    'underpass': {
      AppLanguage.english: 'Underpass',
      AppLanguage.hindi: 'अंडरपास',
    },

    // Voice Templates
    'result_count_announcement': {
      AppLanguage.english: 'Result {0} of {1}',
      AppLanguage.hindi: 'परिणाम {0} में से {1}',
    },
    'saved_place_count_announcement': {
      AppLanguage.english: 'Saved {0} of {1}',
      AppLanguage.hindi: 'सहेजा गया {0} में से {1}',
    },
  };

  // Get translation with argument replacement
  static String translate(String key, {List<String>? args}) {
    var translation = _translations[key]?[_currentLanguage];

    if (translation == null) {
      print('Translation missing for key: $key');
      return key;
    }

    // Replace placeholders with arguments
    if (args != null) {
      String result = translation;
      for (int i = 0; i < args.length; i++) {
        result = result.replaceAll('{$i}', args[i]);
      }
      return result;
    }

    return translation;
  }

  // Shorthand for translate
  static String t(String key, {List<String>? args}) {
    return translate(key, args: args);
  }

  // Translate place name (attempts to translate common place types)
  static String translatePlaceName(String placeName) {
    String lowerName = placeName.toLowerCase();

    // Check if it contains a known place type
    for (var key in _translations.keys) {
      if (_translations[key]?[AppLanguage.english]?.toLowerCase() ==
          lowerName) {
        return translate(key);
      }
    }

    // If no translation found, return original
    return placeName;
  }

  // Translate place description with embedded place types
  static String translatePlaceDescription(String description) {
    String result = description;

    // Try to translate known place types within the description
    for (var key in _translations.keys) {
      String? englishTerm = _translations[key]?[AppLanguage.english];
      if (englishTerm != null &&
          result.toLowerCase().contains(englishTerm.toLowerCase())) {
        String translation = translate(key);
        // Case-insensitive replacement
        result = result.replaceAllMapped(
          RegExp(englishTerm, caseSensitive: false),
          (match) => translation,
        );
      }
    }

    return result;
  }

  // Format distance with translation
  static String formatDistance(double meters) {
    if (meters > 1000) {
      final km = (meters / 1000).toStringAsFixed(1);
      return '$km ${translate("km")}';
    } else {
      final m = meters.round();
      return '$m ${translate("m")}';
    }
  }

  // Format duration with translation
  static String formatDuration(int minutes) {
    if (minutes >= 60) {
      final hours = (minutes / 60).floor();
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours ${translate("hours")}';
      }
      return '$hours ${translate("hours")} $mins ${translate("minutes")}';
    } else {
      return '$minutes ${translate("minutes")}';
    }
  }

  // Check if current language is RTL
  static bool get isRTL => false;

  // Get greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return _currentLanguage == AppLanguage.hindi
          ? 'सुप्रभात'
          : 'Good morning';
    } else if (hour < 17) {
      return _currentLanguage == AppLanguage.hindi
          ? 'नमस्ते'
          : 'Good afternoon';
    } else {
      return _currentLanguage == AppLanguage.hindi
          ? 'शुभ संध्या'
          : 'Good evening';
    }
  }

  // Announce result with proper formatting
  static String formatResultAnnouncement(
    int index,
    int total,
    String mainText,
    String secondaryText,
    String? distance,
  ) {
    // Translate the main text if it's a known place type
    String translatedMain = translatePlaceName(mainText);
    String translatedSecondary = translatePlaceDescription(secondaryText);

    String announcement = translate(
      'result_count_announcement',
      args: [(index + 1).toString(), total.toString()],
    );
    announcement += ": $translatedMain";

    if (translatedSecondary.isNotEmpty) {
      announcement += ", ${translate('located_at')} $translatedSecondary";
    }

    if (distance != null) {
      announcement += ", $distance ${translate('away')}";
    }

    announcement += ". ${translate('use_next_previous_browse')}";
    return announcement;
  }

  // Announce saved place with proper formatting
  static String formatSavedPlaceAnnouncement(
    int index,
    int total,
    String name,
    String address,
    String? distance,
  ) {
    String translatedName = translatePlaceName(name);
    String translatedAddress = translatePlaceDescription(address);

    String announcement = translate(
      'saved_place_count_announcement',
      args: [(index + 1).toString(), total.toString()],
    );
    announcement += ": $translatedName";

    if (translatedAddress.isNotEmpty) {
      announcement += ". ${translate('located_at')} $translatedAddress";
    }

    if (distance != null) {
      announcement += ". $distance ${translate('away')}";
    }

    announcement += ". ${translate('double_tap_to_navigate')}";
    return announcement;
  }

  // Format navigation announcement
  static String formatNavigationStart(
    String destination,
    String distance,
    String duration,
  ) {
    String translatedDestination = translatePlaceName(destination);

    return "${translate('starting_navigation')} $translatedDestination. "
        "${translate('distance')}: $distance. "
        "${translate('time')}: $duration. "
        "${translate('select_stop_next_status_prev_instruction')}";
  }

  // Format turn instruction with translation
  static String formatTurnInstruction(String direction, String distance) {
    final turnKey = direction.toLowerCase().contains('left')
        ? (direction.toLowerCase().contains('slight')
              ? 'slight_left'
              : direction.toLowerCase().contains('sharp')
              ? 'sharp_left'
              : 'turn_left')
        : (direction.toLowerCase().contains('slight')
              ? 'slight_right'
              : direction.toLowerCase().contains('sharp')
              ? 'sharp_right'
              : 'turn_right');

    final inText = translate('in');
    final turnText = translate(turnKey);

    if (inText.isEmpty) {
      return "$distance ${translate('ahead')}, $turnText";
    } else {
      return "$inText $distance, $turnText";
    }
  }

  // Format search query announcement
  static String formatSearchAnnouncement(String query) {
    String translatedQuery = translatePlaceDescription(query);
    return "${translate('searching_for')} $translatedQuery";
  }

  // Format found announcement
  static String formatFoundAnnouncement(String placeName, String? distance) {
    String translatedName = translatePlaceName(placeName);
    String announcement = "${translate('found')} $translatedName";

    if (distance != null) {
      announcement += ", $distance ${translate('away')}";
    }

    announcement += ". ${translate('press_select_to_navigate')}";
    return announcement;
  }

  // Format arrival announcement
  static String formatArrivalAnnouncement(String destination) {
    String translatedDestination = translatePlaceName(destination);
    return "${translate('you_arrived')} $translatedDestination. ${translate('navigation_complete')}";
  }

  // Get all available languages
  static List<Map<String, dynamic>> getAvailableLanguages() {
    return [
      {
        'language': AppLanguage.english,
        'name': translate('english'),
        'nativeName': 'English',
        'code': 'en',
      },
      {
        'language': AppLanguage.hindi,
        'name': translate('hindi'),
        'nativeName': 'हिन्दी',
        'code': 'hi',
      },
    ];
  }
}

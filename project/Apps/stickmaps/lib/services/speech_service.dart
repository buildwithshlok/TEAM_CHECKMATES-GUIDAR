import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'multilingual_service.dart';

class EnhancedSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isListening = false;

  final StreamController<String> _recognizedTextController =
      StreamController<String>.broadcast();
  final StreamController<bool> _speakingStateController =
      StreamController<bool>.broadcast();

  Stream<String> get recognizedTextStream => _recognizedTextController.stream;
  Stream<bool> get speakingStateStream => _speakingStateController.stream;
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;

  // Initialize speech services
  Future<void> initialize() async {
    try {
      // Initialize TTS
      await _initializeTts();

      // Initialize Speech Recognition
      _isInitialized = await _speechToText.initialize(
        onError: (error) => print('Speech recognition error: $error'),
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (_isInitialized) {
        print('Enhanced speech service initialized successfully');
      }
    } catch (e) {
      print('Error initializing speech service: $e');
    }
  }

  Future<void> _initializeTts() async {
    // Set language based on current app language
    await setLanguage(MultilingualService.currentLanguage);

    await _flutterTts.setSpeechRate(0.5); // Slower for clarity
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Set up completion handler
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _speakingStateController.add(false);
    });

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      _speakingStateController.add(true);
    });

    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
      _isSpeaking = false;
      _speakingStateController.add(false);
    });
  }

  // Set language for TTS
  Future<void> setLanguage(AppLanguage language) async {
    final languageCode = MultilingualService.languageCode;
    await _flutterTts.setLanguage(languageCode);
    print('TTS language set to: $languageCode');
  }

  // Speak text with language support
  Future<void> speak(String text, {bool interrupt = true}) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) return;

    print("Speaking: $text");

    if (interrupt && _isSpeaking) {
      await stop();
      // Small delay to ensure previous speech stopped
      await Future.delayed(const Duration(milliseconds: 100));
    }

    try {
      // Ensure correct language is set
      await setLanguage(MultilingualService.currentLanguage);

      _isSpeaking = true;
      _speakingStateController.add(true);
      await _flutterTts.speak(text);
    } catch (e) {
      print('Speak error: $e');
      _isSpeaking = false;
      _speakingStateController.add(false);
    }
  }

  // Stop current speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _speakingStateController.add(false);
    } catch (e) {
      print('Stop error: $e');
    }
  }

  // Start listening for voice input with language support
  Future<void> startListening({
    Duration timeout = const Duration(seconds: 10),
    required Function(String) onResult,
  }) async {
    if (!_isInitialized) {
      print("Speech recognition not initialized");
      await initialize();
      if (!_isInitialized) return;
    }

    if (_isListening) {
      await stopListening();
    }

    // Stop any ongoing speech before listening
    if (_isSpeaking) {
      await stop();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _isListening = true;

    try {
      final localeId = MultilingualService.speechRecognitionCode;
      print('Starting speech recognition with locale: $localeId');

      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            String recognizedText = result.recognizedWords;
            print("Recognized: $recognizedText");
            _recognizedTextController.add(recognizedText);
            onResult(recognizedText);
            stopListening();
          } else {
            // Partial results for real-time feedback
            print("Partial: ${result.recognizedWords}");
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
        localeId: localeId,
      );
    } catch (e) {
      print('Listen error: $e');
      _isListening = false;
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      try {
        await _speechToText.stop();
        _isListening = false;
      } catch (e) {
        print('Stop listening error: $e');
      }
    }
  }

  // Check if speech recognition is available
  Future<bool> isAvailable() async {
    return await _speechToText.initialize();
  }

  // Get available locales
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    return await _speechToText.locales();
  }

  // Predefined multilingual announcements
  Future<void> announceWelcome() async {
    await speak(MultilingualService.t('welcome'));
  }

  Future<void> announceListening() async {
    await speak(
      '${MultilingualService.t('listening')}. ${MultilingualService.t('search_examples')}',
    );
  }

  Future<void> announceSearching(String query) async {
    await speak('${MultilingualService.t('searching_for')} $query');
  }

  Future<void> announceDestinationFound(String location, int count) async {
    if (count == 1) {
      await speak(
        '${MultilingualService.t('found')} $location. ${MultilingualService.t('press_select_to_navigate')}',
      );
    } else {
      await speak(
        '${MultilingualService.t('found')} $count ${MultilingualService.t('places')}. ${MultilingualService.t('browse')}',
      );
    }
  }

  Future<void> announceNavigating(
    String destination,
    String distance,
    String duration,
  ) async {
    await speak(
      '${MultilingualService.t('starting_navigation')} $destination. ${MultilingualService.t('distance')}: $distance. ${MultilingualService.t('time')}: $duration.',
    );
  }

  Future<void> announceTurn(String direction, String distance) async {
    final turnText = direction.toLowerCase() == 'left'
        ? MultilingualService.t('turn_left')
        : MultilingualService.t('turn_right');

    await speak('${MultilingualService.t('in')} $distance, $turnText');
  }

  Future<void> announceDestinationReached(String destination) async {
    await speak(
      '${MultilingualService.t('you_arrived')} $destination. ${MultilingualService.t('navigation_complete')}',
    );
  }

  Future<void> announceError(String error) async {
    await speak(
      '${MultilingualService.t('error')}: $error. ${MultilingualService.t('try_again')}',
    );
  }

  Future<void> announceConnected() async {
    await speak(MultilingualService.t('connected'));
  }

  Future<void> announceDisconnected() async {
    await speak(MultilingualService.t('disconnected'));
  }

  Future<void> announceNextItem(String item, int current, int total) async {
    await speak(
      '${MultilingualService.t('option')} $current ${MultilingualService.t('of')} $total: $item',
    );
  }

  Future<void> announcePreviousItem(String item, int current, int total) async {
    await speak(
      '${MultilingualService.t('option')} $current ${MultilingualService.t('of')} $total: $item',
    );
  }

  Future<void> announceNoResults() async {
    await speak(MultilingualService.t('no_results'));
  }

  Future<void> announceDistanceRemaining(String distance) async {
    await speak('$distance ${MultilingualService.t('remaining')}');
  }

  Future<void> announceRerouting() async {
    await speak(MultilingualService.t('off_route'));
  }

  Future<void> announceSavedSuccessfully(String name) async {
    await speak('$name ${MultilingualService.t('saved_successfully')}');
  }

  Future<void> announceSOSActivated() async {
    await speak('Emergency alert activated. Sending SOS to contacts.');
  }

  Future<void> announceSOSCancelled() async {
    await speak('Emergency alert cancelled.');
  }

  Future<void> announceIncomingCall(String caller) async {
    await speak(
      'Incoming call from $caller. Press call button to answer, hold to reject.',
    );
  }

  Future<void> announceCallAnswered() async {
    await speak('Call answered.');
  }

  Future<void> announceCallEnded() async {
    await speak('Call ended.');
  }

  Future<void> announceBatteryLow(int percentage) async {
    await speak('Battery low: $percentage percent. Please charge soon.');
  }

  Future<void> announceWeatherAlert(String alert) async {
    await speak('Weather alert: $alert');
  }

  // Dispose resources
  void dispose() {
    _recognizedTextController.close();
    _speakingStateController.close();
    _flutterTts.stop();
  }
}

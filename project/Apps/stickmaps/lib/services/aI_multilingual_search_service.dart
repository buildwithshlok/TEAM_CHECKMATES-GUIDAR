import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'multilingual_service.dart';

class AIMultilingualSearchService {
  static const String apiUrl = "https://api.anthropic.com/v1/messages";

  // Enhanced multilingual query processing
  Future<String> enhanceSearchQuery(
    String userInput,
    Position currentPosition,
    String? currentAddress,
    AppLanguage language,
  ) async {
    try {
      final languageName = language == AppLanguage.hindi ? 'Hindi' : 'English';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "anthropic-version": "2023-06-01",
        },
        body: jsonEncode({
          "model": "claude-sonnet-4-20250514",
          "max_tokens": 500,
          "messages": [
            {
              "role": "user",
              "content":
                  """I need help converting a natural language search query into an optimal Google Maps Places API search query. The user is speaking in $languageName.

User's current location: ${currentAddress ?? 'Unknown'}
Coordinates: ${currentPosition.latitude}, ${currentPosition.longitude}
Language: $languageName

User said: "$userInput"

Convert this into a clear, specific English search query that will work best with Google Places API. Consider:

1. If they said "nearest"/"नज़दीकी" or "nearby"/"पास में", keep that context
2. If they mentioned a category (hospital/अस्पताल, restaurant/रेस्तरां, ATM/एटीएम), translate and use that
3. If they mentioned a specific brand (Starbucks, McDonald's), use the exact name
4. If they mentioned a street/area, include that in English
5. Common Hindi place translations:
   - अस्पताल (aspatal) = hospital
   - दवाखाना (davakhana) = pharmacy/medical store
   - रेस्तरां (restaurant) = restaurant
   - होटल (hotel) = hotel
   - बैंक (bank) = bank
   - एटीएम (ATM) = ATM
   - पार्क (park) = park
   - मंदिर (mandir) = temple
   - मस्जिद (masjid) = mosque
   - गिरजाघर (girjaghar) = church
   - स्टेशन (station) = station
   - बस स्टॉप (bus stop) = bus stop
6. Keep it concise and specific

Respond with ONLY the enhanced English search query, nothing else.""",
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String enhanced = data['content'][0]['text'].trim();
        enhanced = enhanced.replaceAll('"', '').replaceAll("'", '');
        return enhanced.isEmpty ? userInput : enhanced;
      } else {
        print("AI API error: ${response.statusCode}");
        return _fallbackEnhancement(userInput, currentAddress, language);
      }
    } catch (e) {
      print("AI enhancement error: $e");
      return _fallbackEnhancement(userInput, currentAddress, language);
    }
  }

  // Fallback enhancement with Hindi support
  String _fallbackEnhancement(
    String userInput,
    String? currentAddress,
    AppLanguage language,
  ) {
    String enhanced = userInput.toLowerCase().trim();

    // Hindi to English translation map
    final Map<String, String> hindiToEnglish = {
      'अस्पताल': 'hospital',
      'दवाखाना': 'pharmacy',
      'दवाई की दुकान': 'medical store',
      'रेस्तरां': 'restaurant',
      'होटल': 'hotel',
      'बैंक': 'bank',
      'एटीएम': 'ATM',
      'पार्क': 'park',
      'मंदिर': 'temple',
      'मस्जिद': 'mosque',
      'गिरजाघर': 'church',
      'स्टेशन': 'station',
      'बस स्टॉप': 'bus stop',
      'पुलिस थाना': 'police station',
      'कॉफी की दुकान': 'coffee shop',
      'चाय की दुकान': 'tea shop',
      'किराना': 'grocery store',
      'दुकान': 'shop',
      'बाजार': 'market',
      'मॉल': 'mall',
      'सिनेमा': 'cinema',
      'थिएटर': 'theater',
      'स्कूल': 'school',
      'कॉलेज': 'college',
      'यूनिवर्सिटी': 'university',
      'नज़दीकी': 'nearest',
      'पास में': 'nearby',
      'करीब': 'near',
    };

    // Translate Hindi words to English
    for (var entry in hindiToEnglish.entries) {
      enhanced = enhanced.replaceAll(entry.key, entry.value);
    }

    // Handle common patterns
    if (enhanced.contains('nearest') ||
        enhanced.contains('nearby') ||
        enhanced.contains('near')) {
      List<String> words = enhanced.split(' ');
      for (int i = 0; i < words.length; i++) {
        if (words[i] == 'nearest' ||
            words[i] == 'nearby' ||
            words[i] == 'near') {
          if (i + 1 < words.length) {
            return words.sublist(i + 1).join(' ');
          }
        }
      }
    }

    // Remove common prefixes
    enhanced = enhanced.replaceAll(
      RegExp(
        r'^(find|get|search|look for|where is|wheres|मुझे|कहाँ है)\s+(a|an|the|)\s*',
      ),
      '',
    );

    // Remove "I want to go to"
    enhanced = enhanced.replaceAll(
      RegExp(r'^(i want to|i need to|take me to|go to|मुझे ले जाओ|जाना है)\s+'),
      '',
    );

    return enhanced;
  }

  // Suggest alternative queries in multiple languages
  Future<List<String>> suggestAlternativeQueries(
    String originalQuery,
    AppLanguage language,
  ) async {
    try {
      final languageName = language == AppLanguage.hindi ? 'Hindi' : 'English';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "anthropic-version": "2023-06-01",
        },
        body: jsonEncode({
          "model": "claude-sonnet-4-20250514",
          "max_tokens": 300,
          "messages": [
            {
              "role": "user",
              "content":
                  """The user searched for: "$originalQuery" in $languageName but no results were found.

Suggest 3 alternative English search queries that might work better. Consider:
- Synonyms or related terms in English
- Broader categories
- Common variations
- If original was in Hindi, provide English translations

Return ONLY a JSON array of 3 English strings, nothing else. Example format:
["alternative 1", "alternative 2", "alternative 3"]""",
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['content'][0]['text'].trim();

        try {
          List<dynamic> alternatives = jsonDecode(content);
          return alternatives.map((e) => e.toString()).toList();
        } catch (e) {
          print("JSON parse error: $e");
          return _fallbackAlternatives(originalQuery, language);
        }
      } else {
        return _fallbackAlternatives(originalQuery, language);
      }
    } catch (e) {
      print("Alternative suggestions error: $e");
      return _fallbackAlternatives(originalQuery, language);
    }
  }

  List<String> _fallbackAlternatives(String query, AppLanguage language) {
    // Multilingual alternatives
    Map<String, List<String>> commonAlternatives = {
      'hospital': ['medical center', 'clinic', 'emergency room'],
      'अस्पताल': ['hospital', 'clinic', 'medical center'],
      'restaurant': ['food', 'dining', 'cafe'],
      'रेस्तरां': ['restaurant', 'food', 'dining'],
      'atm': ['bank', 'cash machine', 'automated teller'],
      'एटीएम': ['ATM', 'bank', 'cash machine'],
      'pharmacy': ['drugstore', 'chemist', 'medical store'],
      'दवाखाना': ['pharmacy', 'medical store', 'chemist'],
      'gas station': ['petrol pump', 'fuel station', 'service station'],
      'hotel': ['accommodation', 'lodging', 'inn'],
      'होटल': ['hotel', 'accommodation', 'lodging'],
      'park': ['garden', 'playground', 'recreation area'],
      'पार्क': ['park', 'garden', 'playground'],
    };

    String lower = query.toLowerCase();
    for (var key in commonAlternatives.keys) {
      if (lower.contains(key)) {
        return commonAlternatives[key]!;
      }
    }

    return [query, '$query near me', 'places named $query'];
  }

  // Get context-aware navigation instructions in user's language
  Future<String> getNavigationGuidance(
    String destination,
    double distanceMeters,
    String currentInstruction,
    AppLanguage language,
  ) async {
    try {
      final languageName = language == AppLanguage.hindi ? 'Hindi' : 'English';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "anthropic-version": "2023-06-01",
        },
        body: jsonEncode({
          "model": "claude-sonnet-4-20250514",
          "max_tokens": 200,
          "messages": [
            {
              "role": "user",
              "content":
                  """Create a clear, concise navigation instruction for a blind person in $languageName.

Destination: $destination
Distance remaining: ${distanceMeters.round()} meters
Current instruction: $currentInstruction

Provide a single, clear sentence in $languageName that a blind person can easily understand. Focus on:
- Direction and distance
- What to do next
- Keep it simple and conversational
- Use natural $languageName phrasing

Respond with ONLY the instruction in $languageName, nothing else.""",
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'].trim();
      } else {
        return _fallbackGuidance(distanceMeters, currentInstruction, language);
      }
    } catch (e) {
      print("Navigation guidance error: $e");
      return _fallbackGuidance(distanceMeters, currentInstruction, language);
    }
  }

  String _fallbackGuidance(
    double distanceMeters,
    String instruction,
    AppLanguage language,
  ) {
    final distance = MultilingualService.formatDistance(distanceMeters);

    if (language == AppLanguage.hindi) {
      return "$instruction। $distance के लिए जारी रखें।";
    } else {
      return "$instruction. Continue for $distance.";
    }
  }

  // Interpret complex user commands in multiple languages
  Future<Map<String, dynamic>> interpretCommand(
    String userInput,
    AppLanguage language,
  ) async {
    try {
      final languageName = language == AppLanguage.hindi ? 'Hindi' : 'English';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "anthropic-version": "2023-06-01",
        },
        body: jsonEncode({
          "model": "claude-sonnet-4-20250514",
          "max_tokens": 300,
          "messages": [
            {
              "role": "user",
              "content":
                  """Interpret this user command in $languageName for a smart blind stick navigation app:

"$userInput"

Determine the intent and extract relevant information. Return ONLY a JSON object with this structure:
{
  "intent": "search" | "navigate" | "help" | "status" | "cancel",
  "query": "extracted search query if intent is search (in English)",
  "details": "any additional context"
}

Example inputs and outputs:
- "find nearest hospital"/"नज़दीकी अस्पताल ढूंढें" → {"intent": "search", "query": "hospital", "details": "nearest"}
- "where am I"/"मैं कहाँ हूँ" → {"intent": "status", "query": "", "details": "location"}
- "help"/"सहायता" → {"intent": "help", "query": "", "details": "general"}""",
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['content'][0]['text'].trim();

        try {
          return jsonDecode(content);
        } catch (e) {
          return _fallbackInterpretation(userInput, language);
        }
      } else {
        return _fallbackInterpretation(userInput, language);
      }
    } catch (e) {
      print("Command interpretation error: $e");
      return _fallbackInterpretation(userInput, language);
    }
  }

  Map<String, dynamic> _fallbackInterpretation(
    String input,
    AppLanguage language,
  ) {
    String lower = input.toLowerCase();

    // Help patterns
    if (lower.contains('help') ||
        lower.contains('सहायता') ||
        lower.contains('what can')) {
      return {"intent": "help", "query": "", "details": "general"};
    }

    // Status patterns
    if (lower.contains('where am i') ||
        lower.contains('current location') ||
        lower.contains('मैं कहाँ हूँ') ||
        lower.contains('वर्तमान स्थान')) {
      return {"intent": "status", "query": "", "details": "location"};
    }

    // Cancel patterns
    if (lower.contains('stop') ||
        lower.contains('cancel') ||
        lower.contains('रोको') ||
        lower.contains('रद्द करें')) {
      return {"intent": "cancel", "query": "", "details": "navigation"};
    }

    // Default to search
    return {"intent": "search", "query": input, "details": ""};
  }
}

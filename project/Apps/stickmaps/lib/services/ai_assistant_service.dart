import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class AIAssistantService {
  // Use Claude API to enhance search queries
  static const String apiUrl = "https://api.anthropic.com/v1/messages";

  // This will be called to enhance user's natural language queries
  Future<String> enhanceSearchQuery(
    String userInput,
    Position currentPosition,
    String? currentAddress,
  ) async {
    try {
      // Use Claude API to understand and enhance the query
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
                  """I need help converting a natural language search query into an optimal Google Maps Places API search query.

User's current location: ${currentAddress ?? 'Unknown'}
Coordinates: ${currentPosition.latitude}, ${currentPosition.longitude}

User said: "$userInput"

Convert this into a clear, specific search query that will work best with Google Places API. Consider:
1. If they said "nearest" or "nearby", keep that context
2. If they mentioned a category (hospital, restaurant, ATM), use that
3. If they mentioned a specific brand (Starbucks, McDonald's), use the exact name
4. If they mentioned a street/area, include that
5. Keep it concise and specific

Respond with ONLY the enhanced search query, nothing else.""",
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String enhanced = data['content'][0]['text'].trim();
        // Remove any quotes that might be added
        enhanced = enhanced.replaceAll('"', '').replaceAll("'", '');
        return enhanced.isEmpty ? userInput : enhanced;
      } else {
        print("AI API error: ${response.statusCode}");
        return _fallbackEnhancement(userInput, currentAddress);
      }
    } catch (e) {
      print("AI enhancement error: $e");
      return _fallbackEnhancement(userInput, currentAddress);
    }
  }

  // Fallback enhancement if AI API fails
  String _fallbackEnhancement(String userInput, String? currentAddress) {
    String enhanced = userInput.toLowerCase().trim();

    // Handle common patterns
    if (enhanced.contains('nearest') || enhanced.contains('nearby')) {
      // Extract the type of place
      List<String> words = enhanced.split(' ');
      for (int i = 0; i < words.length; i++) {
        if (words[i] == 'nearest' || words[i] == 'nearby') {
          if (i + 1 < words.length) {
            return words.sublist(i + 1).join(' ');
          }
        }
      }
    }

    // Handle "find a/an/the"
    enhanced = enhanced.replaceAll(
      RegExp(r'^(find|get|search|look for|where is|wheres)\s+(a|an|the|)\s*'),
      '',
    );

    // Handle "i want to go to"
    enhanced = enhanced.replaceAll(
      RegExp(r'^(i want to|i need to|take me to|go to)\s+'),
      '',
    );

    return enhanced;
  }

  // Suggest alternative queries if initial search fails
  Future<List<String>> suggestAlternativeQueries(String originalQuery) async {
    try {
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
                  """The user searched for: "$originalQuery" but no results were found.

Suggest 3 alternative search queries that might work better. Consider:
- Synonyms or related terms
- Broader categories
- Common variations

Return ONLY a JSON array of 3 strings, nothing else. Example format:
["alternative 1", "alternative 2", "alternative 3"]""",
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['content'][0]['text'].trim();

        // Parse JSON array
        try {
          List<dynamic> alternatives = jsonDecode(content);
          return alternatives.map((e) => e.toString()).toList();
        } catch (e) {
          print("JSON parse error: $e");
          return _fallbackAlternatives(originalQuery);
        }
      } else {
        return _fallbackAlternatives(originalQuery);
      }
    } catch (e) {
      print("Alternative suggestions error: $e");
      return _fallbackAlternatives(originalQuery);
    }
  }

  List<String> _fallbackAlternatives(String query) {
    // Simple fallback alternatives
    Map<String, List<String>> commonAlternatives = {
      'hospital': ['medical center', 'clinic', 'emergency room'],
      'restaurant': ['food', 'dining', 'cafe'],
      'atm': ['bank', 'cash machine', 'automated teller'],
      'pharmacy': ['drugstore', 'chemist', 'medical store'],
      'gas station': ['petrol pump', 'fuel station', 'service station'],
      'hotel': ['accommodation', 'lodging', 'inn'],
      'park': ['garden', 'playground', 'recreation area'],
    };

    String lower = query.toLowerCase();
    for (var key in commonAlternatives.keys) {
      if (lower.contains(key)) {
        return commonAlternatives[key]!;
      }
    }

    return [query, '$query near me', 'places named $query'];
  }

  // Get context-aware navigation instructions
  Future<String> getNavigationGuidance(
    String destination,
    double distanceMeters,
    String currentInstruction,
  ) async {
    try {
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
                  """Create a clear, concise navigation instruction for a blind person.

Destination: $destination
Distance remaining: ${distanceMeters.round()} meters
Current instruction: $currentInstruction

Provide a single, clear sentence that a blind person can easily understand. Focus on:
- Direction and distance
- What to do next
- Keep it simple and conversational

Respond with ONLY the instruction, nothing else.""",
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'].trim();
      } else {
        return _fallbackGuidance(distanceMeters, currentInstruction);
      }
    } catch (e) {
      print("Navigation guidance error: $e");
      return _fallbackGuidance(distanceMeters, currentInstruction);
    }
  }

  String _fallbackGuidance(double distanceMeters, String instruction) {
    String distance = distanceMeters > 1000
        ? "${(distanceMeters / 1000).toStringAsFixed(1)} kilometers"
        : "${distanceMeters.round()} meters";

    return "$instruction. Continue for $distance.";
  }

  // Interpret complex user commands
  Future<Map<String, dynamic>> interpretCommand(String userInput) async {
    try {
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
                  """Interpret this user command for a smart blind stick navigation app:

"$userInput"

Determine the intent and extract relevant information. Return ONLY a JSON object with this structure:
{
  "intent": "search" | "navigate" | "help" | "status" | "cancel",
  "query": "extracted search query if intent is search",
  "details": "any additional context"
}

Example inputs and outputs:
- "find nearest hospital" → {"intent": "search", "query": "hospital", "details": "nearest"}
- "where am I" → {"intent": "status", "query": "", "details": "location"}
- "help" → {"intent": "help", "query": "", "details": "general"}""",
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
          return _fallbackInterpretation(userInput);
        }
      } else {
        return _fallbackInterpretation(userInput);
      }
    } catch (e) {
      print("Command interpretation error: $e");
      return _fallbackInterpretation(userInput);
    }
  }

  Map<String, dynamic> _fallbackInterpretation(String input) {
    String lower = input.toLowerCase();

    if (lower.contains('help') || lower.contains('what can')) {
      return {"intent": "help", "query": "", "details": "general"};
    } else if (lower.contains('where am i') ||
        lower.contains('current location')) {
      return {"intent": "status", "query": "", "details": "location"};
    } else if (lower.contains('stop') || lower.contains('cancel')) {
      return {"intent": "cancel", "query": "", "details": "navigation"};
    } else {
      return {"intent": "search", "query": input, "details": ""};
    }
  }
}

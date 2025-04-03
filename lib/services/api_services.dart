// api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MusicRecommendationService {
  static String get _openAiKey => dotenv.env['tokenOpenAi']!;
  static String get _lastFmKey => dotenv.env['tokenLastFm']!;

  // Main recommendation method
  static Future<List<Map<String, String>>> getRecommendations({
    required String mood,
    required List<String> genres,
  }) async {
    try {
      // Try Last.fm first
      try {
        final lastFmResults = await _getLastFmRecommendations(mood, genres);
        if (lastFmResults.isNotEmpty) return lastFmResults;
      } catch (e) {
        print('Last.fm failed: $e');
      }

      // Fallback to OpenAI
      try {
        return await _getOpenAiRecommendations(mood, genres);
      } catch (e) {
        print('OpenAI failed: $e');
        return _getMockRecommendations();
      }
    } catch (e) {
      print('All APIs failed: $e');
      return _getMockRecommendations();
    }
  }

// Last.fm Implementation
  static Future<List<Map<String, String>>> _getLastFmRecommendations(
      String mood, List<String> genres) async {
    final cache = Hive.box('music_recommendations_cache');
    final cacheKey = 'lastfm_${mood}_${genres.join(',')}';

    // Check cache first
    if (cache.containsKey(cacheKey)) {
      return List<Map<String, String>>.from(cache.get(cacheKey));
    }

    // Map moods to Last.fm tags
    final moodTags = {
      'happy': 'happy',
      'sad': 'sad',
      'energetic': 'energetic',
      'relaxed': 'chill',
      'heartbroken': 'sad',
      'grateful': 'happy',
      'anxious': 'anxious',
      'romance': 'love',
    };

    final tag = moodTags[mood.toLowerCase()] ?? genres.first.toLowerCase();

    final response = await http.get(
      Uri.parse('http://ws.audioscrobbler.com/2.0/?method=tag.gettoptracks'
          '&tag=$tag'
          '&api_key=$_lastFmKey'
          '&limit=10'
          '&format=json'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final tracks = data['tracks']['track'] as List;

      // Explicitly convert dynamic types to String
      final results = tracks.map<Map<String, String>>((track) {
        return {
          'artist': track['artist']['name'].toString(),
          'title': track['name'].toString(),
        };
      }).toList();

      cache.put(cacheKey, results);
      return results;
    } else {
      throw Exception('Last.fm API failed with status ${response.statusCode}');
    }
  }

  // OpenAI Implementation
  static Future<List<Map<String, String>>> _getOpenAiRecommendations(
      String mood, List<String> genres) async {
    final cache = Hive.box('music_recommendations_cache');
    final cacheKey = 'openai_${mood}_${genres.join(',')}';

    if (cache.containsKey(cacheKey)) {
      return List<Map<String, String>>.from(cache.get(cacheKey));
    }

    final promptText = 'Give me a 10-song music playlist for '
        'Mood: $mood, Genres: ${genres.join(', ')}. '
        'Format strictly as: "Artist - Title" one per line. '
        'Only return the list, no additional text.';

    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_openAiKey"
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "user", "content": promptText},
        ],
        "max_tokens": 500,
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final content = data['choices'][0]['message']['content'];

      final playlist =
          content.split('\n').where((line) => line.contains(' - ')).map((line) {
        final parts = line.split(' - ');
        return {
          'artist': parts[0].trim(),
          'title': parts[1].trim().replaceAll('"', ''),
        };
      }).toList();

      if (playlist.isNotEmpty) {
        cache.put(cacheKey, playlist);
        return playlist;
      } else {
        throw Exception('OpenAI returned empty playlist');
      }
    } else {
      throw Exception('OpenAI API failed with status ${response.statusCode}');
    }
  }

  // Mock data fallback
  static List<Map<String, String>> _getMockRecommendations() {
    return [
      {'artist': 'Daft Punk', 'title': 'Get Lucky'},
      {'artist': 'Pharrell Williams', 'title': 'Happy'},
      {'artist': 'The Weeknd', 'title': 'Blinding Lights'},
      {'artist': 'Billie Eilish', 'title': 'bad guy'},
      {'artist': 'Post Malone', 'title': 'Sunflower'},
    ];
  }
}

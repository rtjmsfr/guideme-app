import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';

class TranslationService {
  static const String _baseUrl =
      'http://127.0.0.1:5050'; // ✅ غيّريه لـ IP السيرفر لو Emulator
  static final Box _cacheBox = Hive.box('translations');

  static Future<Map<String, String>> translate({
    required List<String> texts,
    required String from,
    required String to,
  }) async {
    final Map<String, String> result = {};

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': texts,
          'source_lang': from,
          'target_lang': to,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['translations'] != null && data['translations'] is List) {
          for (var item in data['translations']) {
            final original = item['text'];
            final translated = item['translated'];
            result[original] = translated;
          }
        }
      } else {
        print('❌ الترجمة فشلت: ${response.body}');
      }
    } catch (e) {
      print('⚠️ استثناء أثناء الترجمة: $e');
    }
    return result;
  }

  static Future<void> clearCache() async {
    await _cacheBox.clear();
  }

  static Future<Map<String, String>> fetchSupportedLanguages() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/languages'));
      if (response.statusCode == 200) {
        return Map<String, String>.from(jsonDecode(response.body));
      } else {
        print('❌ فشل في تحميل اللغات: ${response.body}');
        return {};
      }
    } catch (e) {
      print('⚠️ Exception loading languages: $e');
      return {};
    }
  }
}

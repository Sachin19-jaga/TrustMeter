import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _key = 'exam_results';

  static Future<void> saveResult(ExamResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getAllResults();
    existing.add(result);
    await prefs.setString(_key, ExamResult.encodeList(existing));
  }

  static Future<List<ExamResult>> getAllResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    return ExamResult.decodeList(raw);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

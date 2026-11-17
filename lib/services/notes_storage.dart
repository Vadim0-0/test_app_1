import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/note_models.dart';

class NotesStorage {
  static const _key = 'notes_data_v1';

  final _preferences = SharedPreferencesAsync();

  Future<NotesData> load() async {
    final saved = await _preferences.getString(_key);

    if (saved == null) {
      return const NotesData(categories: [], notes: []);
    }

    return NotesData.fromJson(jsonDecode(saved) as Map<String, dynamic>);
  }

  Future<void> save(NotesData data) async {
    await _preferences.setString(_key, jsonEncode(data.toJson()));
  }
}

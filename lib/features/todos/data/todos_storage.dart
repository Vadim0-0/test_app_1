import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo.dart';

class TodosStorage {
  final _preferences = SharedPreferencesAsync();
  static const _key = 'todos';

  Future<List<Todo>> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((item) => Todo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<Todo> todos) => _preferences.setString(
    _key,
    jsonEncode(todos.map((todo) => todo.toJson()).toList()),
  );
}

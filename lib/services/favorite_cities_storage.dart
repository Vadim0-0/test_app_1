import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather_models.dart';

class FavoriteCitiesStorage {
  static const _key = 'weather_favorite_cities_v1';

  final _preferences = SharedPreferencesAsync();

  Future<List<WeatherCity>> load() async {
    final saved = await _preferences.getString(_key);

    if (saved == null) {
      return [];
    }

    final items = jsonDecode(saved) as List<dynamic>;

    return items.map((item) {
      return WeatherCity.fromJson(item as Map<String, dynamic>);
    }).toList();
  }

  Future<void> save(List<WeatherCity> cities) async {
    final items = cities.map((city) => city.toJson()).toList();

    await _preferences.setString(_key, jsonEncode(items));
  }
}

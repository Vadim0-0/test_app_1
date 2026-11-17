import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_app_1/features/weather/controllers/weather_controller.dart';
import 'package:test_app_1/features/weather/data/weather_service.dart';
import 'package:test_app_1/features/weather/data/favorite_cities_storage.dart';
import 'package:test_app_1/features/weather/models/weather_models.dart';

const city = WeatherCity(
  name: 'Казань',
  country: 'RU',
  latitude: 55,
  longitude: 49,
);

class SearchService extends WeatherService {
  final result = Completer<List<WeatherCity>>();
  @override
  Future<List<WeatherCity>> findCities(String name) => result.future;
}

class MemoryFavorites implements FavoriteCitiesStorage {
  bool fail = false;
  List<WeatherCity> cities = [];
  @override
  Future<List<WeatherCity>> load() async => cities;
  @override
  Future<void> save(List<WeatherCity> value) async {
    if (fail) throw StateError('Write failed');
    cities = value;
  }
}

void main() {
  test('Изменение текста не позволяет применить старый ответ поиска', () async {
    final service = SearchService();
    final controller = WeatherController(
      service: service,
      storage: MemoryFavorites(),
    );
    addTearDown(controller.dispose);
    final pending = controller.search('Казань');
    controller.onSearchChanged('Москва');
    service.result.complete([city]);
    await pending;
    expect(controller.searchResults, isEmpty);
    expect(controller.hasSubmittedSearch, isFalse);
    expect(controller.isSearching, isFalse);
  });

  test('Избранное меняется только после успешного сохранения', () async {
    final storage = MemoryFavorites();
    final controller = WeatherController(storage: storage);
    addTearDown(controller.dispose);
    await controller.loadFavorites();
    storage.fail = true;
    expect(
      await controller.toggleFavorite(city),
      'Не удалось сохранить избранное',
    );
    expect(controller.favorites, isEmpty);
    storage.fail = false;
    await controller.toggleFavorite(city);
    expect(controller.isFavorite(city), isTrue);
    await controller.toggleFavorite(city);
    expect(controller.favorites, isEmpty);
  });
}

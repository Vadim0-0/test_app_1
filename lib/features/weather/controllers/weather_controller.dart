import 'package:flutter/foundation.dart';

import '../models/weather_models.dart';
import '../data/weather_service.dart';
import '../data/favorite_cities_storage.dart';

class WeatherController extends ChangeNotifier {
  WeatherController({WeatherService? service, FavoriteCitiesStorage? storage})
    : _service = service ?? WeatherService(),
      _storage = storage ?? FavoriteCitiesStorage();
  final WeatherService _service;
  final FavoriteCitiesStorage _storage;
  bool _disposed = false;
  String _query = '';
  bool _hasSubmittedSearch = false;
  bool get isSearchMode => _query.trim().isNotEmpty;
  void _change(VoidCallback change) {
    if (_disposed) return;
    change();
    notifyListeners();
  }

  // Сохранение Future, чтобы перестроение экрана не запускало повторные запросы.
  final _requests = <String, Future<WeatherData>>{};

  // Список избранных городов
  List<WeatherCity> _favorites = [];
  // Список городов при поиске
  List<WeatherCity> _searchResults = [];

  bool _isLoadingFavorites =
      true; // Показывате, ваполняеется ли загрузка избранных городов
  bool _isSavingFavorites =
      false; // Показывате, ваполняеется ли сохранение избранных городов
  bool _isSearching = false; // Показывате, ваполняеется ли поиск

  String? _favoritesError;
  String? _searchError; // Хранит текст ошибки, если есть

  // Счётчик версий поиска. Позволяет игнорировать устаревший результат поиска.
  int _searchVersion = 0;

  // Принимает город и возвращает строку с его координатами
  String cityKey(WeatherCity city) {
    return '${city.latitude}:${city.longitude}';
  }

  // Проверяет наличие в избранном
  bool isFavorite(WeatherCity city) {
    final key = cityKey(city);

    return _favorites.any((favorite) => cityKey(favorite) == key);
  }

  // возвращает запрос погоды
  Future<WeatherData> weatherFor(WeatherCity city) {
    // Метод putIfAbsent означает: «если ключ отсутствует — добавь значение».
    return _requests.putIfAbsent(
      cityKey(city),
      () => _service.getWeather(city),
    );
  }

  // Загрузка избранных городов
  Future<void> loadFavorites() async {
    // Включение загрузки и очищение старой загрузки
    _change(() {
      _isLoadingFavorites = true;
      _favoritesError = null;
    });

    try {
      // Чтение хранилища
      final cities = await _storage.load();

      if (_disposed) return;

      // Сохранение занруженного города
      _change(() {
        _favorites = cities;
      });
    } catch (_) {
      if (_disposed) return;

      _change(() {
        _favoritesError = 'Не удалось загрузить избранное';
      });
    } finally {
      if (!_disposed) {
        _change(() {
          _isLoadingFavorites = false;
        });
      }
    }
  }

  // Добавление или удаления из избранного
  Future<String?> toggleFavorite(WeatherCity city) async {
    // Проверка доступности операции
    if (_isSavingFavorites || _isLoadingFavorites || _favoritesError != null) {
      return null;
    }

    // Сохранение прежнего состояния
    final wasFavorite = isFavorite(city);

    // Копия списка
    final updated = List<WeatherCity>.of(_favorites);

    // Изменение копии
    if (wasFavorite) {
      updated.removeWhere((item) => cityKey(item) == cityKey(city));
    } else {
      updated.add(city);
    }

    _change(() {
      _isSavingFavorites = true;
    });

    try {
      // Сохранение и обновления интерфейса
      await _storage.save(updated);

      if (_disposed) return null;

      _change(() {
        _favorites = updated;
      });

      return wasFavorite
          ? '${city.name}: удалён из избранного'
          : '${city.name}: добавлен в избранное';
    } catch (_) {
      if (_disposed) return null;
      return 'Не удалось сохранить избранное';
    } finally {
      if (!_disposed) {
        _change(() {
          _isSavingFavorites = false;
        });
      }
    }
  }

  // Поиск города
  Future<void> search(String value) async {
    _query = value;
    _hasSubmittedSearch = value.trim().isNotEmpty;
    final version = ++_searchVersion;
    final query = value.trim();

    if (query.isEmpty) {
      _change(() {
        _searchResults = [];
        _searchError = null;
        _isSearching = false;
      });
      return;
    }

    if (query.length < 2) {
      _change(() {
        _searchResults = [];
        _searchError = 'Введите хотя бы два символа';
        _isSearching = false;
      });
      return;
    }

    _change(() {
      _isSearching = true;
      _searchError = null;
      _searchResults = [];
    });

    try {
      final cities = await _service.findCities(query);

      if (_disposed || version != _searchVersion) return;

      _change(() {
        _searchResults = cities;
      });
    } catch (_) {
      if (_disposed || version != _searchVersion) return;

      _change(() {
        _searchError = 'Не удалось выполнить поиск. Проверьте интернет.';
      });
    } finally {
      if (!_disposed && version == _searchVersion) {
        _change(() {
          _isSearching = false;
        });
      }
    }
  }

  // Обновление
  Future<String?> refreshWeather() async {
    // Обновление городов, которые отображаются
    final cities = List<WeatherCity>.of(
      isSearchMode ? _searchResults : _favorites,
    );

    if (cities.isEmpty) return null;

    final newRequests = <String, Future<WeatherData>>{
      for (final city in cities) cityKey(city): _service.getWeather(city),
    };

    // Карточки получают новые Future и показывают загрузку.
    _change(() {
      _requests.addAll(newRequests);
    });

    try {
      // Индикатор обновления работает, пока запросы не завершатся.
      await Future.wait(newRequests.values);
    } catch (_) {
      if (_disposed) return null;

      return 'Не удалось обновить погоду для некоторых городов';
    }
    return null;
  }

  // Обработка изменения ввода
  void onSearchChanged(String value) {
    _query = value;
    _hasSubmittedSearch = false;
    _searchVersion++;

    _change(() {
      _searchResults = [];
      _searchError = null;
      _isSearching = false;
    });
  }

  // Повторная загрузка погоды
  void retry(WeatherCity city) {
    _change(() {
      _requests.remove(cityKey(city));
    });
  }

  String get query => _query;
  bool get hasSubmittedSearch => _hasSubmittedSearch;
  List<WeatherCity> get favorites => List.unmodifiable(_favorites);
  List<WeatherCity> get searchResults => List.unmodifiable(_searchResults);
  bool get isLoadingFavorites => _isLoadingFavorites;
  bool get isSavingFavorites => _isSavingFavorites;
  bool get isSearching => _isSearching;
  String? get favoritesError => _favoritesError;
  String? get searchError => _searchError;

  @override
  void dispose() {
    _disposed = true;
    _searchVersion++;
    super.dispose();
  }
}

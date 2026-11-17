import 'package:flutter/material.dart';

import '../models/weather_models.dart';
import '../services/favorite_cities_storage.dart';
import '../services/weather_service.dart';
import '../widgets/city_weather_card.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  // Сервис через который который экран ищет города и получает погоду
  final _service = WeatherService();
  // Контроллер текстового поля. Позволяет прочитать введённый текст через _searchController.text
  final _searchController = TextEditingController();
  final _storage = FavoriteCitiesStorage();

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

  // Непустое поле означает режим поиска.
  bool get _isSearchMode => _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  // Принимает город и возвращает строку с его координатами
  String _cityKey(WeatherCity city) {
    return '${city.latitude}:${city.longitude}';
  }

  // Проверяет наличие в избранном
  bool _isFavorite(WeatherCity city) {
    final key = _cityKey(city);

    return _favorites.any((favorite) => _cityKey(favorite) == key);
  }

  // возвращает запрос погоды
  Future<WeatherData> _weatherFor(WeatherCity city) {
    // Метод putIfAbsent означает: «если ключ отсутствует — добавь значение».
    return _requests.putIfAbsent(
      _cityKey(city),
      () => _service.getWeather(city),
    );
  }

  // Загрузка избранных городов
  Future<void> _loadFavorites() async {
    // Включение загрузки и очищение старой загрузки
    setState(() {
      _isLoadingFavorites = true;
      _favoritesError = null;
    });

    try {
      // Чтение хранилища
      final cities = await _storage.load();

      if (!mounted) return;

      // Сохранение занруженного города
      setState(() {
        _favorites = cities;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _favoritesError = 'Не удалось загрузить избранное';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFavorites = false;
        });
      }
    }
  }

  // Добавление или удаления из избранного
  Future<void> _toggleFavorite(WeatherCity city) async {
    // Проверка доступности операции
    if (_isSavingFavorites || _isLoadingFavorites || _favoritesError != null) {
      return;
    }

    // Сохранение прежнего состояния
    final wasFavorite = _isFavorite(city);

    // Копия списка
    final updated = List<WeatherCity>.of(_favorites);

    // Изменение копии
    if (wasFavorite) {
      updated.removeWhere((item) => _cityKey(item) == _cityKey(city));
    } else {
      updated.add(city);
    }

    setState(() {
      _isSavingFavorites = true;
    });

    try {
      // Сохранение и обновления интерфейса
      await _storage.save(updated);

      if (!mounted) return;

      setState(() {
        _favorites = updated;
      });

      // Временное уведомление внизу экрана.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFavorite
                ? '${city.name}: удалён из избранного'
                : '${city.name}: добавлен в избранное',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить избранное')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingFavorites = false;
        });
      }
    }
  }

  // Открытие меню города при длительном нажатии
  Future<void> _showCityActions(WeatherCity city) async {
    if (_isSavingFavorites || _isLoadingFavorites || _favoritesError != null) {
      return;
    }

    final favorite = _isFavorite(city);

    final shouldToggle = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(title: Text(city.name), subtitle: Text(city.country)),
                ListTile(
                  leading: Icon(favorite ? Icons.star_border : Icons.star),
                  title: Text(
                    favorite ? 'Убрать из избранного' : 'Добавить в избранное',
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop(true);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || shouldToggle != true) return;

    await _toggleFavorite(city);
  }

  // Поиск города
  Future<void> _search(String value) async {
    final version = ++_searchVersion;
    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = null;
        _isSearching = false;
      });
      return;
    }

    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _searchError = 'Введите хотя бы два символа';
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResults = [];
    });

    try {
      final cities = await _service.findCities(query);

      if (!mounted || version != _searchVersion) return;

      setState(() {
        _searchResults = cities;
      });
    } catch (_) {
      if (!mounted || version != _searchVersion) return;

      setState(() {
        _searchError = 'Не удалось выполнить поиск. Проверьте интернет.';
      });
    } finally {
      if (mounted && version == _searchVersion) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // Обработка изменения ввода
  void _onSearchChanged(String value) {
    // Отображение нового запроса
    _searchVersion++;

    setState(() {
      _searchResults = [];
      _searchError = null;
      _isSearching = false;
    });
  }

  // Очищение поля
  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  // Повторная загрузка погоды
  void _retry(WeatherCity city) {
    setState(() {
      _requests.remove(_cityKey(city));
    });
  }

  // Общий виджет сообщения по центру экрана
  Widget _centerMessage(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoritesError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_favoritesError!),
            TextButton(
              onPressed: _loadFavorites,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_isSearchMode && _isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isSearchMode && _searchError != null) {
      return _centerMessage(_searchError!);
    }

    final cities = _isSearchMode ? _searchResults : _favorites;

    if (cities.isEmpty) {
      if (!_isSearchMode) {
        return _centerMessage(
          'Избранных городов нет, '
          'введите в поиске нужный город',
        );
      }

      return _centerMessage(
        _searchError == null && !_hasSubmittedSearch
            ? 'Нажмите поиск на клавиатуре или кнопку справа'
            : 'Города не найдены',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final city = cities[index];

        return CityWeatherCard(
          key: ValueKey(_cityKey(city)),
          city: city,
          request: _weatherFor(city),
          onRetry: () => _retry(city),
          onLongPress: () => _showCityActions(city),

          // Рамка только у избранных в результатах поиска.
          highlightFavorite: _isSearchMode && _isFavorite(city),
        );
      },
    );
  }

  // Отличие результата поиска от ситуакции, когда рользователь вводит текст
  bool _hasSubmittedSearch = false;

  // Подтверждение поиска
  void _submitSearch(String value) {
    _hasSubmittedSearch = value.trim().isNotEmpty;
    _search(value);
  }

  // Освобождение ресурса
  @override
  void dispose() {
    // Освобождает ресурсы контроллера текстового поля
    _searchController.dispose();
    // Вызывает реализацию очистки из родительского класса State
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSearchMode ? 'Поиск городов' : 'Избранные города'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              enabled: !_isLoadingFavorites && _favoritesError == null, // Блокировка при загрузке из избранного или при поиске
              textInputAction: TextInputAction.search,
              onSubmitted: _submitSearch, // поиск с клавиатуры
              // реакция на изменение текста
              onChanged: (value) {
                _hasSubmittedSearch = false;
                _onSearchChanged(value);
              },
              decoration: InputDecoration(
                hintText: 'Поиск города',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Кнопка очистки
                    if (_isSearchMode)
                      IconButton(
                        tooltip: 'Очистить',
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      ),
                    IconButton(
                      tooltip: 'Найти',
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _isLoadingFavorites || _favoritesError != null
                          ? null
                          : () => _submitSearch(_searchController.text),
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (_isSavingFavorites) const LinearProgressIndicator(),
          Expanded(child: _buildContent()),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Данные о погоде: Open-Meteo.com (CC BY 4.0)',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

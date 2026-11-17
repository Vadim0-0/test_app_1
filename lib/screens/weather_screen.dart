import 'package:flutter/material.dart';

import '../models/weather_models.dart';
import '../services/weather_service.dart';
import '../widgets/city_weather_card.dart';

// Список, который показывается при пустом поиске.
final _cities = <WeatherCity>[
  const WeatherCity(
    name: 'Москва',
    country: 'RU',
    latitude: 55.7558,
    longitude: 37.6173,
  ),
  const WeatherCity(
    name: 'Санкт-Петербург',
    country: 'RU',
    latitude: 59.9343,
    longitude: 30.3351,
  ),
  const WeatherCity(
    name: 'Казань',
    country: 'RU',
    latitude: 55.7963,
    longitude: 49.1088,
  ),
  const WeatherCity(
    name: 'Новосибирск',
    country: 'RU',
    latitude: 55.0084,
    longitude: 82.9357,
  ),
  const WeatherCity(
    name: 'Екатеринбург',
    country: 'RU',
    latitude: 56.8389,
    longitude: 60.6057,
  ),
]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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

  // Сохранение Future, чтобы перестроение экрана не запускало повторные запросы.
  final _requests = <String, Future<WeatherData>>{};

  // Список городов, которые отоюражаются при загрузке
  List<WeatherCity> _visibleCities = List.of(_cities);

  bool _isSearching = false; // Показывате, ваполняеется ли посик
  String? _searchError; // Хранит текст ошибки, если есть

  // Счётчик версий поиска. Позволяет игнорировать устаревший результат поиска.
  int _searchVersion = 0;

  // Принимает город и возвращает строку с его координатами
  String _cityKey(WeatherCity city) {
    return '${city.latitude}:${city.longitude}';
  }

  // возвращает запрос погоды
  Future<WeatherData> _weatherFor(WeatherCity city) {
    // Метод putIfAbsent означает: «если ключ отсутствует — добавь значение».
    return _requests.putIfAbsent(
      _cityKey(city),
      () => _service.getWeather(city),
    );
  }

  // Поиск города
  Future<void> _search(String value) async {
    // Увеличение счётчика
    final version = ++_searchVersion;
    final query = value.trim();

    if (query.isEmpty) {
      setState(() {
        _visibleCities = List.of(_cities);
        _isSearching = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchError = null;
    });

    try {
      // Поиск города
      final city = await _service.findCity(query);

      // !mounted — этот объект состояния уже не находится в дереве виджетов
      // version != _searchVersion — после начала запроса пользователь изменил ввод или запустил другой поиск
      if (!mounted || version != _searchVersion) return;

      setState(() {
        _visibleCities = [city];
      });
    } catch (_) {
      if (!mounted || version != _searchVersion) return;

      setState(() {
        _visibleCities = [];
        _searchError = 'Не удалось найти город. Проверьте название и сеть.';
      });
    } finally {
      if (mounted && version == _searchVersion) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  // Удаление сохранённый запрос для конкретного города и запускает перестроение интерфейса.
  void _retry(WeatherCity city) {
    setState(() {
      _requests.remove(_cityKey(city));
    });
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
      appBar: AppBar(title: const Text('Погода')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _search, // поиск с клавиатуры
              // реакция на изменение текста
              onChanged: (_) {
                // Уже запущенный поиск больше не соответствует вводу.
                _searchVersion++;

                if (_searchController.text.trim().isEmpty) {
                  _search('');
                } else {
                  setState(() {
                    _isSearching = false;
                    _searchError = null;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: 'Введите город и нажмите поиск',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _search(_searchController.text),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          if (_isSearching) const LinearProgressIndicator(),
          if (_searchError != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_searchError!),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _visibleCities.length,
              itemBuilder: (context, index) {
                final city = _visibleCities[index];

                return CityWeatherCard(
                  key: ValueKey(_cityKey(city)),
                  city: city,
                  request: _weatherFor(city),
                  onRetry: () => _retry(city),
                );
              },
            ),
          ),
          Padding(
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

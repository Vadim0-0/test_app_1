import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/weather_models.dart';

class WeatherService {
  // Получение погоды по координатам города.
  Future<WeatherData> getWeather(WeatherCity city) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': city.latitude.toString(),
      'longitude': city.longitude.toString(),

      // Показатели погоды сейчас.
      'current': [
        'temperature_2m',
        'relative_humidity_2m',
        'apparent_temperature',
        'weather_code',
        'wind_speed_10m',
      ].join(','),

      // Почасовые показатели.
      'hourly': [
        'temperature_2m',
        'relative_humidity_2m',
        'apparent_temperature',
        'precipitation_probability',
        'weather_code',
        'wind_speed_10m',
        'is_day',
      ].join(','),

      // Даты дней прогноза.
      'daily': 'temperature_2m_max',

      'timezone': 'auto',
      'temperature_unit': 'celsius',
      'wind_speed_unit': 'ms',
      'forecast_days': '7',
    });

    final json = await _getJson(uri);
    return _parseWeather(json);
  }

  // Поиск города по названию.
  Future<WeatherCity> findCity(String name) async {
    final query = name.trim();

    if (query.length < 2) {
      throw Exception('Введите хотя бы два символа');
    }

    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': query,
      'count': '1',
      'language': 'ru',
      'format': 'json',
    });

    final json = await _getJson(uri);
    final results = json['results'] as List<dynamic>?;

    if (results == null || results.isEmpty) {
      throw Exception('Город «$query» не найден');
    }

    final city = results.first as Map<String, dynamic>;

    return WeatherCity(
      name: city['name'] as String,
      country:
          city['country'] as String? ?? city['country_code'] as String? ?? '',
      latitude: (city['latitude'] as num).toDouble(),
      longitude: (city['longitude'] as num).toDouble(),
    );
  }

  // Общая отправка запроса и проверка ответа.
  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception('Ошибка Open-Meteo: ${response.statusCode}');
      }

      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (json['error'] == true) {
        throw Exception(json['reason'] as String? ?? 'Ошибка Open-Meteo');
      }

      return json;
    } on TimeoutException {
      throw Exception('Сервер не ответил. Попробуйте ещё раз');
    } on http.ClientException {
      throw Exception(
        'Не удалось подключиться к Open-Meteo. '
        'Проверьте интернет',
      );
    }
  }

  WeatherData _parseWeather(Map<String, dynamic> json) {
    final currentJson = json['current'] as Map<String, dynamic>;

    final hourlyJson = json['hourly'] as Map<String, dynamic>;

    final dailyJson = json['daily'] as Map<String, dynamic>;

    // Даты и часы приходят уже в местном времени города.
    final times = (hourlyJson['time'] as List<dynamic>)
        .map((value) => DateTime.parse(value as String))
        .toList();

    final temperatures = hourlyJson['temperature_2m'] as List<dynamic>;

    final humidity = hourlyJson['relative_humidity_2m'] as List<dynamic>;

    final apparentTemperatures =
        hourlyJson['apparent_temperature'] as List<dynamic>;

    final precipitation =
        hourlyJson['precipitation_probability'] as List<dynamic>;

    final weatherCodes = hourlyJson['weather_code'] as List<dynamic>;

    final windSpeeds = hourlyJson['wind_speed_10m'] as List<dynamic>;

    final isDay = hourlyJson['is_day'] as List<dynamic>;

    // Если показатель отсутствует, не подменяем его нулём.
    double number(dynamic value) {
      if (value is! num) {
        throw Exception('В прогнозе отсутствует один из показателей');
      }

      return value.toDouble();
    }

    final currentCode = (currentJson['weather_code'] as num).toInt();

    final current = CurrentWeather(
      temperature: number(currentJson['temperature_2m']),
      feelsLike: number(currentJson['apparent_temperature']),
      humidity: number(currentJson['relative_humidity_2m']).round(),
      windSpeed: number(currentJson['wind_speed_10m']),
      description: _weatherDescription(currentCode),

      // Open-Meteo возвращает код погоды, а не код
      // изображения OpenWeather. Пока иконку не используем.
      icon: '',
    );

    final hourly = <ForecastPoint>[
      for (var index = 0; index < times.length; index++)
        ForecastPoint(
          time: times[index],
          temperature: number(temperatures[index]),
          isDay: isDay[index] == 1,
        ),
    ];

    final dates = dailyJson['time'] as List<dynamic>;
    final daily = <DailyForecast>[];

    for (final value in dates) {
      final date = DateTime.parse(value as String);

      // Индексы всех часов, относящихся к этому дню.
      final indexes = <int>[
        for (var index = 0; index < times.length; index++)
          if (_sameDay(times[index], date)) index,
      ];

      if (indexes.isEmpty) {
        throw Exception('Нет почасовых данных для одного из дней');
      }

      // Ищем доступную запись, ближайшую к нужному часу.
      int nearestHour(int hour) {
        return indexes.reduce((best, candidate) {
          final bestDistance = (times[best].hour - hour).abs();

          final candidateDistance = (times[candidate].hour - hour).abs();

          return candidateDistance < bestDistance ? candidate : best;
        });
      }

      final dayIndex = nearestHour(14);
      final nightIndex = nearestHour(2);

      var maxPrecipitation = 0.0;

      for (final index in indexes) {
        final probability = number(precipitation[index]);

        if (probability > maxPrecipitation) {
          maxPrecipitation = probability;
        }
      }

      final dayCode = number(weatherCodes[dayIndex]).toInt();

      daily.add(
        DailyForecast(
          date: date,
          dayTemperature: number(temperatures[dayIndex]),
          nightTemperature: number(temperatures[nightIndex]),
          feelsLike: number(apparentTemperatures[dayIndex]),
          humidity: number(humidity[dayIndex]).round(),
          precipitationProbability: maxPrecipitation / 100,
          windSpeed: number(windSpeeds[dayIndex]),
          description: _weatherDescription(dayCode),
        ),
      );
    }

    return WeatherData(current: current, hourly: hourly, daily: daily);
  }

  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _weatherDescription(int code) {
    return switch (code) {
      0 => 'Ясно',
      1 => 'Преимущественно ясно',
      2 => 'Переменная облачность',
      3 => 'Пасмурно',
      45 || 48 => 'Туман',
      51 || 53 || 55 => 'Морось',
      56 || 57 => 'Переохлаждённая морось',
      61 || 63 || 65 => 'Дождь',
      66 || 67 => 'Переохлаждённый дождь',
      71 || 73 || 75 => 'Снег',
      77 => 'Снежные зёрна',
      80 || 81 || 82 => 'Ливень',
      85 || 86 => 'Снежный ливень',
      95 => 'Гроза',
      96 || 99 => 'Гроза с градом',
      _ => 'Нет описания погоды',
    };
  }
}

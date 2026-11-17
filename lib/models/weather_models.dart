// Город
class WeatherCity {
  final String name;
  final String country;
  final double latitude;
  final double longitude;

  const WeatherCity({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  // Фабричный конструктор
  factory WeatherCity.fromJson(Map<String, dynamic> json) => WeatherCity(
    name: json['name'] as String,
    country: json['country'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

// Текушая погода
class CurrentWeather {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;

  const CurrentWeather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
  });
}

// Точка прогноза
class ForecastPoint {
  final DateTime time;
  final double temperature;
  final bool isDay;

  const ForecastPoint({
    required this.time,
    required this.temperature,
    required this.isDay,
  });
}

// Прогноз на день
class DailyForecast {
  final DateTime date;
  final double dayTemperature;
  final double nightTemperature;
  final double feelsLike;
  final int humidity;
  final double precipitationProbability;
  final double windSpeed;
  final String description;

  const DailyForecast({
    required this.date,
    required this.dayTemperature,
    required this.nightTemperature,
    required this.feelsLike,
    required this.humidity,
    required this.precipitationProbability,
    required this.windSpeed,
    required this.description,
  });
}

// Общий результат
class WeatherData {
  final CurrentWeather current;
  final List<ForecastPoint> hourly;
  final List<DailyForecast> daily;

  const WeatherData({
    required this.current,
    required this.hourly,
    required this.daily,
  });
}

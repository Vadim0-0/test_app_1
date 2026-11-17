// Список погодных показателей. Отображает переданные состояния, поэтому StatelessWidget
import 'package:flutter/material.dart';

import '../models/weather_models.dart';

class WeatherDetails extends StatelessWidget {
  final DailyForecast day;
  final CurrentWeather? current;

  const WeatherDetails({required this.day, required this.current});

  @override
  Widget build(BuildContext context) {
    final now = current;

    final values = <(String, String)>[
      if (now != null) ...[
        ('Сейчас', '${now.temperature.round()} °C'),
        ('Ощущается сейчас', '${now.feelsLike.round()} °C'),
        ('Влажность сейчас', '${now.humidity}%'),
        ('Ветер сейчас', '${now.windSpeed.toStringAsFixed(1)} м/с'),
      ],
      ('Температура в 14:00', '${day.dayTemperature.round()} °C'),
      ('Температура в 02:00', '${day.nightTemperature.round()} °C'),
      ('Ощущается в 14:00', '${day.feelsLike.round()} °C'),
      ('Влажность в 14:00', '${day.humidity}%'),
      (
        'Макс. вероятность осадков за час',
        '${(day.precipitationProbability * 100).round()}%',
      ),
      ('Ветер в 14:00', '${day.windSpeed.toStringAsFixed(1)} м/с'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(day.description, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final value in values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(value.$1)),
                const SizedBox(width: 16),
                Text(
                  value.$2,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

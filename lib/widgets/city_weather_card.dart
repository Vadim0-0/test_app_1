// карточка погоды одного города
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather_models.dart';
import 'temperature_chart.dart';
import 'weather_details.dart';

class CityWeatherCard extends StatefulWidget {
  final WeatherCity city;
  final Future<WeatherData> request;
  final VoidCallback onRetry;

  const CityWeatherCard({
    super.key,
    required this.city,
    required this.request,
    required this.onRetry,
  });

  // создание состояния карточки
  @override
  State<CityWeatherCard> createState() => CityWeatherCardState();
}

// хранится выбранный день и находится код построения интерфейса
class CityWeatherCardState extends State<CityWeatherCard> {
  int _selectedDayIndex = 0;

  // Совпаление дат
  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // Подпись дня
  String _dayLabel(int index, DateTime date) {
    if (index == 0) return 'Сегодня';
    if (index == 1) return 'Завтра';

    return DateFormat('dd.MM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias, // Обрезание содержимого по форме карточки
      margin: const EdgeInsets.only(bottom: 12),
      child: FutureBuilder<WeatherData>(
        // обращение из объекта State к параметру текущего виджета
        future: widget.request,
        // snapshot - содержит состояние запроса, данные или ошибку.
        builder: (context, snapshot) {
          // Если запрос ещё не завершён, то показывать название города и индикатор загрузки справа
          if (snapshot.connectionState != ConnectionState.done) {
            return ListTile(
              title: Text(widget.city.name),
              trailing: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }

          // Если запрос завершён с ошибкой или без данных, то отобразить надписб и кнопку "Повторить"
          if (snapshot.hasError || !snapshot.hasData) {
            return ListTile(
              title: Text(widget.city.name),
              subtitle: const Text('Не удалось загрузить погоду'),
              trailing: IconButton(
                tooltip: 'Повторить',
                icon: const Icon(Icons.refresh),
                onPressed: widget.onRetry,
              ),
            );
          }

          // Получение данных
          final data = snapshot.data!;

          if (data.daily.isEmpty) {
            return ListTile(
              title: Text(widget.city.name),
              subtitle: const Text('Нет ежедневного прогноза'),
            );
          }

          final selectedIndex = _selectedDayIndex < data.daily.length
              ? _selectedDayIndex
              : 0;

          final day = data.daily[selectedIndex];

          // Точки на графике
          final points =
              data.hourly
                  .where(
                    (point) => _sameDay(point.time, day.date),
                  ) // оставляет почасовые точки за выбранную дату
                  .toList() // собирает их в отдельный список
                ..sort(
                  (a, b) => a.time.compareTo(b.time),
                ); // сортирует по времени от раннего к позднему

          // Средняя температура за день
          final double? averageTemperature = points.isEmpty
              ? null
              : points
                        .map((point) => point.temperature)
                        .reduce((sum, temperature) => sum + temperature) /
                    points.length;

          // Раскрывающаяся часть карточки
          return ExpansionTile(
            // Позволяет Flutter сохранять состояние раскрытия в хранилище страницы и связывать его с конкретным городом
            key: PageStorageKey(
              'weather:${widget.city.latitude}:${widget.city.longitude}',
            ),
            // Сохранение состояния дочерних виджетов, когда карточка сворачивается.
            maintainState: true,
            title: Text(widget.city.name),
            subtitle: Text(widget.city.country),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // В свёрнутом виде отображаются город, страна и текущая температура:
                Text(
                  '${data.current.temperature.round()}°',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.expand_more),
              ],
            ),
            childrenPadding: const EdgeInsets.all(16),
            children: [
              // 1. График.
              Text(
                'Температура · ${DateFormat('dd.MM').format(day.date)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              // Показ графика
              if (points.isEmpty)
                const SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      'Почасовой прогноз на этот день недоступен',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                TemperatureChart(points: points),

              // Отображение средней температуры за день
              if (averageTemperature != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Средняя за день: '
                    '${averageTemperature.toStringAsFixed(1)} °C',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

              // 2. Горизонтальный выбор дней.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var index = 0; index < data.daily.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_dayLabel(index, data.daily[index].date)),
                          selected: selectedIndex == index,
                          onSelected: (selected) {
                            if (!selected) return;

                            setState(() {
                              _selectedDayIndex = index;
                            });
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. Подробности выбранного дня.
              WeatherDetails(
                day: day,
                current: selectedIndex == 0 ? data.current : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather_models.dart';

// Объявления виджета
// StatelessWidget означает, что у графика нет собственного изменяемого состояния. Если родительский экран передаст новый список точек, Flutter заново вызовет build() и построит обновлённый график.
class TemperatureChart extends StatelessWidget {
  // Список точек
  final List<ForecastPoint> points;

  const TemperatureChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(child: Text('Нет данных для графика'));
    }

    // Создание списка. FLSpot - одна точка графика с координатами
    // FlSpot(x, y). x - порядковый номер точки. y - температура
    final spots = <FlSpot>[
      for (var index = 0; index < points.length; index++)
        FlSpot(index.toDouble(), points[index].temperature),
    ];

    // Размер графика
    return SizedBox(
      height: 240,
      // Виджет, который рисует график
      child: LineChart(
        // объект с его настройками: линии, осьми, сеткой и подписями.
        LineChartData(
          // Стили всплывающей подсказки
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.round()} °C',
                    const TextStyle(
                      color: Colors.white, // Цвет текста.
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
              getTooltipColor: (spot) => Colors.indigo,
            ),
          ),

          // Сетка и границы
          gridData: const FlGridData(
            show: true, // показать сетку
            drawVerticalLine: false, // не рисовать вертикальные линии
          ),

          // Рамка вокруг графика
          borderData: FlBorderData(
            show: false, // Скрыть рамку
          ),

          // Скрытие верхней и правой осей
          titlesData: FlTitlesData(
            // Верхние значекния
            topTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false, // Скрыть
              ),
            ),

            // Праве значения
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false, // Скрыть
              ),
            ),

            // Левые значения
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, // Показать
                reservedSize: 30, // Резервирование пикселей слева. Чтобы текст не наложился друг на друга
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    //правильно располагает подпись относительно оси
                    meta: meta, // содержит служебную информацию о её положении
                    child: Text('${value.round()}°'),
                  );
                },
              ),
            ),

            // Нижние значения
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 1, // сообщает fl_chart, что подписи нужно проверять для каждой целой координаты.
                // В value приходит координата x, которую ранее создали из индекса
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  // Проверка границ списка
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }

                  // Подпись показывается только у каждой третьей точки,
                  // чтобы время не сливалось.
                  if (index % 3 != 0) {
                    return const SizedBox.shrink();
                  }

                  // Форматирование времени
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      // Формат 14 часов 30 минут преобразуется в 14:30
                      DateFormat('HH:mm').format(points[index].time),
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),

          // Построение линии
          // lineBarsData — это список линий. Сейчас в нём только одна линия, поэтому график показывает один показатель — температуру.
          lineBarsData: [
            LineChartBarData(
              spots: spots, // Передача подготовленных точек
              isCurved: true, // Делает линию плавной. Без этого параметра точки соединялись бы прями отрезками.
              barWidth: 3, // Задаёт толщину линии.
              color: Theme.of(context).colorScheme.primary,
              dotData: const FlDotData(
                show: true,
              ), // Показывает кружок в каждой точке
              // Добавляет полупрозрачную заливку между линией и нижней частью графика.
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../widgets/animated_dropdown.dart';

// Название единиц и функция перерасчёта
class Conversion {
  final String from;
  final String to;
  final double Function(double) convert;

  const Conversion(this.from, this.to, this.convert);
}

// Список всех конвертаций
final List<Conversion> conversions = [
  Conversion('km', 'miles', (v) => v * 0.621371),
  Conversion('miles', 'km', (v) => v / 0.621371),
  Conversion('C', 'F', (v) => v * 9 / 5 + 32),
  Conversion('F', 'C', (v) => (v - 32) * 5 / 9),
  Conversion('KG', 'ID', (v) => v * 2.20462),
  Conversion('ID', 'KG', (v) => v / 2.20462),
];

// Виджет с состоянием
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

// Состояние

// Класс состояния
class _ConverterScreenState extends State<ConverterScreen> {
  // Контроллер тестового поля. Через него можно прочитать текст (_controller.text), изменить его или очистить. Он связывается с TextField
  final _controller = TextEditingController();

  // Выбранная сейчас конвертация. При старте белётся первая из списка
  Conversion _selected = conversions.first;

  // Освобождение ресурсов

  // dispose() — метод, который Flutter вызывает, когда экран закрывается навсегда (например, вы нажали «Назад»).
  @override
  void dispose() {
    // Освобождение памяти контроллерав
    _controller.dispose();

    // вызывает версию метода у родителя
    super.dispose();
  }

  // Вычисление результата

  // Геттер, каждый раз вычисляется заново
  String get _result {
    // _controller.text - текст, который ввёл пользователь
    // запятая заменятеся на точку
    // double.tryParse - заменяет строку на число. Если не получилось, возращает null
    final input = double.tryParse(_controller.text.replaceAll(',', '.'));

    // Если введенно не число, то показывается прочерк и прекращается выполнение
    if (input == null) return '-';

    // Вызывается фенкция, которая была выбрана или превая из списка
    final output = _selected.convert(input);

    return '${output.toStringAsFixed(2)} ${_selected.to}';
  }

  // Отрисовка
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Converter')),

      // Padding — обёртка, которая добавляет отступ 16 со всех сторон.
      body: Padding(
        padding: const EdgeInsets.all(16),

        // Вертикальная колонка
        // crossAxisAligment - Выравнивание поперёк колонки(по горизонтали)
        // stretch - растягивание элемента на всю ширину
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            /*
            DropdownMenu<Conversion>(
              // Какой пункт сейчас выбран и показан
              initialSelection: _selected,

              // Растянуть кнопку на всю ширину
              expandedInsets: EdgeInsets.zero,

              label: const Text('Конвертация'),

              // Привращение списка правил в список пунктов меню
              // .map() - проходит по каждому правилу и превращает в в item
              // value: c - какой обёект вернётся, если вабрать этот пункт
              // child: Text() - что отображается на экране
              // .toList() нужен потому, что map возвращает «ленивую» последовательность (Iterable), а items ждёт именно List.
              dropdownMenuEntries: conversions
                  .map(
                    (c) => DropdownMenuEntry(
                      value: c,
                      label: '${c.from} → ${c.to}',
                    ),
                  )
                  .toList(),

              // Что делать при выборе. c имеет тип Conversion?, потому что теоретически может прийти null, отсюда проверка. Внутри setState запоминаем выбор, и экран перерисовывается: меняются подпись поля и результат.
              onSelected: (c) {
                if (c != null) setState(() => _selected = c);
              },
            ),
          */

            AnimatedDropdown<Conversion>(
              label: 'Конвертация',
              value: _selected,
              items: conversions,
              labelOf: (c) => '${c.from} → ${c.to}',
              onChanged: (c) => setState(() => _selected = c),
            ),

            // Отступ
            const SizedBox(height: 16),

            TextField(
              // Поле ввода, связанное с контроллером. Всё, что вводит пользователь, появляется в _controller.text.
              controller: _controller,

              // Какую клавиатуру показать на телефоне: цифровую, с точкой или запятой (decimal) и с минусом (signed).
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),

              // Оформление поля
              // labelText - подпись, например "Значение (км). Менется вместе с выбором в списке"
              // OutlineInputBorder() — рамка вокруг поля.
              decoration: InputDecoration(
                labelText: 'Значение (${_selected.from})',
                border: const OutlineInputBorder(),
              ),

              // Вызывается на каждый введённый символ.
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 32),

            // Результат
            Text(
              _result,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
          // Выпадающий список
        ),
      ),
    );
  }
}

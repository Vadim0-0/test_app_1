import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _value = 0; // Текущее значение
  final List<String> _history = []; // Список строк истории. final значит, что сам список заменить нельзя, но добавлять и удалять элементы можно.

  // Форматируем время вручную, чтобы не подключать пакет intl.
  String _time() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }

  void _change(int delta) {
    // setState говорит Flutter: "данные изменились, вызови build() заново".
    // Если поменять _value без setState, на экране ничего не обновится.
    setState(() {
      _value += delta;
      final sign = delta > 0 ? '+' : '';
      _history.insert(
        0,
        '$sign$delta в ${_time()}  →  $_value',
      ); // новые сверху
    });
  }

  void _reset() {
    setState(() {
      _value = 0;
      _history.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Счётчик'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: _reset,
          ),
        ],
      ),
      body: Column(
        children: [
          // Отступ Сверху
          const SizedBox(height: 32),

          // Само число. '$_value' превращает int в строку.
          // Theme.of(context).textTheme.displayLarge берёт из темы приложения самый крупный стиль текста.
          Text('$_value', style: Theme.of(context).textTheme.displayLarge),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () => _change(-1),
                child: const Icon(Icons.remove),
              ),
              const SizedBox(width: 24),
              FilledButton(
                onPressed: () => _change(1),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const Divider(height: 48),
          // Expanded отдаёт списку всё оставшееся место.
          // Без него ListView внутри Column падает с ошибкой
          // "unbounded height": у списка нет ограничения по высоте.
          Expanded(
            child: _history.isEmpty
                ? const Center(child: Text('История пуста'))
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, i) => ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(_history[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

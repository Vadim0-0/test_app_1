import 'dart:convert'; // jsonDecode
import 'dart:math'; // Random

import 'package:flutter/material.dart';
// rootBundle — доступ к файлам, вшитым в приложение (ассетам).
import 'package:flutter/services.dart'; // rootBundle

// Модель цитаты
class Quote {
  final String text;
  final String author;

  const Quote(this.text, this.author);

  // Фабричный конструктор
  // Обычный коструктор сам заполняет аоля, а фаьричный может выполнить люьой код и вернуть объект. В данном случае, достаёт из Map значения по ключам и передаёт их в обычный конструктор
  // Map<String, dynamic>: ключи — строки, значения — что угодно (JSON может содержать строки, числа, списки).
  //as String говорит Dart: «я уверен, что тут строка». Если там окажется не строка, будет ошибка.
  factory Quote.fromJson(Map<String, dynamic> json) =>
      Quote(json['text'] as String, json['author'] as String);
}

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

// Состояние
class _QuotesScreenState extends State<QuotesScreen> {
  final _random = Random(); // Генератор случайных чисел
  List<Quote> _quotes = []; // Все загруженные цитаты. Не finsl потому что после загрузки присваивается новый список
  Quote? _current; // Значение может быть null, до загрузки ничего не показывать

  bool _loading = true;
  String? _error;

  // Запуск загрузки
  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  // Загрузка цитат
  Future<void> _loadQuotes() async {
    try {
      final raw = await rootBundle.loadString('assets/quotes.json');
      final List<dynamic> data = jsonDecode(raw);
      final quotes = data.map((e) => Quote.fromJson(e)).toList();

      // Пока шла загрузка, пользователь мог закрыть экран. setState у закрытого экрана вызвал бы ошибку.
      if (!mounted) return;

      // Созранение цитат, отображается загрузка и сразу показывается рандомная цитата
      setState(() {
        _quotes = quotes;
        _loading = false;
      });
      _next();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загркзть цитаты: $e';
        _loading = false;
      });
    }
  }

  // Следующая цитата
  void _next() {
    if (_quotes.isEmpty) return;

    setState(() {
      Quote q;
      // Цикл, который выполняется хотя бы один раз и повторяется, пока условие истино
      do {
        q =
            _quotes[_random.nextInt(
              _quotes.length,
            )]; // Случацное число от 0 до n-1
      } while (_quotes.length > 1 && q == _current);
      _current = q;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Каркас Экрана
    return Scaffold(
      appBar: AppBar(
        title: const Text('Цитаты'), //TODO: Узнать, почему через const
      ),
      body: Center(child: _buildBody(context)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _next,
        icon: const Icon(Icons.casino),
        label: const Text('Новая цитата'),
      ),
    );
  }

  // Содержимое три состояния
  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const CircularProgressIndicator(); // Индикатор во время загрузки
    } // Индикатор во время загрузки
    if (_error != null) return Text(_error!); // null нет

    final quote = _current!; // _current иммет значения
    final colors = Theme.of(context).colorScheme; // Политра темы

    // Анимированная карточка
    // AnimatedSwitcher плавно заменяет один виджет другим: старый растворяется, новый проявляется за 400 мс.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(
          quote.text,
        ), // Кдюч для того, чтобы была анимаия при смене карточек
        margin: const EdgeInsets.all(24), // Наружний отступ от края экрана
        padding: const EdgeInsets.all(28), // Внутренний отступ от края карточки
        // Фон - градиент по диагонали из жвех цвето
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primaryContainer, colors.tertiaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),

          borderRadius: BorderRadius.circular(24), // Скругление
          // Тень
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.15,
              ), // Чёрная с прозрачностью 15%
              blurRadius: 20, // Размытие
              offset: const Offset(0, 8), // Сдвиг тени на 8px вниз
            ),
          ],
        ),

        // Колонка занимает по васоте столько, сколько надо сожердимому, не растяшиваясь на все экран
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.format_quote, size: 48, color: colors.primary),
            const SizedBox(height: 12),

            // Текст цитаты
            Text(
              quote.text,
              textAlign: TextAlign.center, // Расположение по центру
              // copyWith(...) берёт стиль из темы и меняет только указанное (здесь курсив), остальное остаётся как было.
              // ?. вызывает метод, только если объект не null. Стиль titleLarge в теории может отсутствовать.
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 20),

            // Align выравнивает один дочерний виджет внутри доступного места
            Align(
              alignment: AlignmentGeometry.centerRight,
              child: Text(
                "- ${quote.author}",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

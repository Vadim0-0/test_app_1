import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/counter_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/todo_screen.dart';
import 'screens/quotes_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/notes_screen.dart';

// main() — точка входа. runApp запускает корневой виджет.
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await dotenv.load(fileName: '.env');

//   runApp(const MyApp());
// }

void main() {
  runApp(const MyApp());
}

// MaterialApp задаёт тему, заголовок и стартовый экран.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Practice',
      debugShowCheckedModeBanner: false, // убирает ленту "DEBUG"
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}

// Описание одного пункта меню: так список экранов не дублирует код.
class DemoItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder builder; // функция, которая создаёт экран

  const DemoItem(this.title, this.subtitle, this.icon, this.builder);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      DemoItem(
        'Счётчик с историей',
        'StatefulWidget, setState, ListView',
        Icons.exposure,
        (_) => const CounterScreen(),
      ),
      DemoItem(
        'Конвертер единиц',
        'TextField, DropdownButton, числа',
        Icons.swap_horiz,
        (_) => const ConverterScreen(),
      ),
      DemoItem(
        'To-Do лист',
        'ListView.builder, Dismissible',
        Icons.checklist,
        (_) => const TodoScreen(),
      ),
      DemoItem(
        'Случайные цитаты',
        'async/await, локальный JSON',
        Icons.format_quote,
        (_) => const QuotesScreen(),
      ),
      DemoItem(
        'Фотографии',
        'Ваши фотографии',
        Icons.photo_library,
        (_) => const GalleryScreen(),
      ),
      DemoItem(
        'Погода',
        'Проноз погоды',
        Icons.device_thermostat,
        (_) => const WeatherScreen(),
      ),
      DemoItem(
        'Заметки',
        'Категории и личные записи',
        Icons.note_alt_outlined,
        (_) => const NotesScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Мои учебные приложения')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              leading: Icon(item.icon, size: 32),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: item.builder),
              ),
            ),
          );
        },
      ),
    );
  }
}

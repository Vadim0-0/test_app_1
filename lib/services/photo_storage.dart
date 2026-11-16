import 'dart:convert'; // jsonEncode / jsonDecode
import 'dart:io'; // File, Directory — работа с файлами

import 'package:path/path.dart' as p; // p.join, p.extension
import 'package:path_provider/path_provider.dart'; // getApplicationDocumentsDirectory
import 'package:shared_preferences/shared_preferences.dart';

import '../models/photo_entry.dart';

// Отвечает за сохранение альбома:
// - сами фото лежат файлами в папке приложения;
// - описания, даты и имена файлов — JSON-строкой в shared_preferences.
class PhotoStorage {
  static const _key = 'photos'; // ключ в shared_preferences
  final _prefs = SharedPreferencesAsync();

  // Папка для фото: <папка приложения>/photos. Создаём, если её ещё нет.
  Future<Directory> _photosDir() async {
    final docs = await getApplicationCacheDirectory(); // Возращает путь к расположению папки приложения в ОС
    final dir = Directory(
      p.join(docs.path, 'photos'),
    ); // добавляет раздулитель(photos) к пути

    if (!await dir.exists()) {
      // Проверяет есть ли папка на диске
      await dir.create(recursive: true); // Если папки нет, то создаёт папку
    }
    return dir; // Возращает папку
  }

  // Записать байты фото в файл.
  Future<void> saveFile(PhotoEntry photo) async {
    final dir = await _photosDir();
    final file = File(p.join(dir.path, photo.fileName));
    await file.writeAsBytes(photo.bytes, flush: true);
  }

  // Удалить файл фото
  Future<void> deleteFile(PhotoEntry photo) async {
    final dir = await _photosDir();
    final file = File(p.join(dir.path, photo.fileName));
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Сохранить список описаний (без байтов).
  Future<void> saveList(List<PhotoEntry> photos) async {
    final raw = jsonEncode(photos.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, raw);
  }

  // Загрузить весь альбом: описания из prefs + байты из файлов.
  Future<List<PhotoEntry>> load() async {
    final raw = await _prefs.getString(_key); // Приходит одна строка Json
    if (raw == null) return [];

    final dir = await _photosDir();
    final result = <PhotoEntry>[];

    for (final item in jsonDecode(raw) as List) {
      final json = item as Map<String, dynamic>;
      final fileName = json['fileName'] as String;
      final file = File(p.join(dir.path, fileName));

      // Файла нет (удалён, повреждён) — пропускаем запись, а не падаем.
      if (!await file.exists()) continue;

      result.add(
        PhotoEntry.restore(
          id: json["id"] as String,
          bytes: await file.readAsBytes(),
          description: json['description'] as String,
          createdAt: DateTime.parse(json['createdAt'] as String),
          extension: p.extension(fileName),
        ),
      );
    }

    return result;
  }
}

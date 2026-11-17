// Uint8List — это "массив байтов", то есть сырое содержимое файла картинки.
import 'dart:typed_data';

// Класс. Описание одной записи в альбоме
class PhotoEntry {
  final String id; // Id для записи

  final Uint8List bytes; // Байьы изображения

  final String description; // Описание изображения

  final DateTime createdAt; // Дата создания записи

  final String extension; // расширение С точкой: ".jpg", ".png"

  // 1-й конструктор — для НОВОГО фото: id и дату генерирует сам.
  // Конструктор. Обязатеьные поля передаются по имени
  // После : идут поля, которые вычисляются автоматически
  PhotoEntry({
    required this.bytes,
    required this.description,
    required this.extension,
  }) : id = DateTime.now().microsecondsSinceEpoch.toString(),
       createdAt = DateTime.now();

  // 2-й, именованный конструктор — для ВОССТАНОВЛЕНИЯ: ничего не генерирует,
  // все поля приходят готовыми, поэтому используем только this.поле.
  PhotoEntry.restore({
    required this.id,
    required this.bytes,
    required this.description,
    required this.createdAt,
    required this.extension,
  });

  // Геттер: вычисляется каждый раз при обращении, отдельно не хранится.
  // Пишется как поле: entry.fileName, без скобок.
  String get fileName => '$id$extension'; // "1761734400123456" + ".jpg"

  // Превращаем объект в Map, который понимает jsonEncode. Байтов здесь НЕТ.
  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'fileName': fileName,
  };
}

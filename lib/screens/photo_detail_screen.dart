import 'package:flutter/material.dart';

import '../models/photo_entry.dart';

import '../widgets/confirm_delete_dialog.dart';

// Экран ничего не меняет, только показывает, поэтому Stateless
class PhotoDetailScreen extends StatelessWidget {
  final PhotoEntry photo; // Запись, котороу отобразить пришла из GalleryScreen

  const PhotoDetailScreen({
    super.key,
    required this.photo,
  }); // фото обязательно передать при создании

  // Форматирование даты
  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0'); // 5 → "05"
    return '${two(d.day)}.${two(d.month)}.${d.year}'
        '${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              final confirmed = await confirmDelete(context);

              if (!confirmed || !context.mounted) return;

              // Сообщаем галерее, что это фото нужно удалить
              Navigator.pop(context, true);
            },
            tooltip: 'Удалить фото',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            // фото занимает всё место, кроме описания
            child: InteractiveViewer(
              // Позволяет приближать двумя пальцами
              minScale: 1, // Нельзя уменьшить меньше исходного
              maxScale: 5, // Максимум можно увеличить в 5раз
              child: Hero(
                // пара для Hero из списка
                tag: photo.id, // для анимации перехода
                child: Image.memory(
                  photo.bytes,
                  fit: BoxFit.contain, // показать ЦЕЛИКОМ, без обрезки (по краям чёрные поля)
                  width:
                      double.infinity, // растянуть по ширине доступного места
                  height: double
                      .infinity, // и по высоте; contain сохранит пропорции
                ),
              ),
            ),
          ),

          // отступ от "чёлки" / полоски жестов внизу iPhone
          SafeArea(
            top: false, // Без отступа сверху, так как там AppBar
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade900, // тёмно-серая подложка под текстом
              child: ConstrainedBox(
                // ограничивает высоту блока описания,
                constraints: const BoxConstraints(
                  maxHeight: 200,
                ), // чтобы длинный текст не вытеснил фото
                child: SingleChildScrollView(
                  // если текст длиннее 200 px, его можно прокрутить
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo.description.isEmpty
                            ? 'Без описания'
                            : photo.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(photo.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/photo_entry.dart';

class PhotoCard extends StatelessWidget {
  final PhotoEntry photo;
  final VoidCallback onTap;
  final ValueChanged<Offset> onLongPress;
  const PhotoCard({
    super.key,
    required this.photo,
    required this.onTap,
    required this.onLongPress,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias, // обрезать содержимое (фото) по скруглённым углам карточки
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPressStart: (details) {
          onLongPress(details.globalPosition);
        },
        child: InkWell(
          // кликабельная область + эффект волны
          onTap: onTap,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Текст выравнивается по левому краю
            children: [
              Hero(
                // анимация "перелёта" картинки на следующий экран
                tag: photo.id, // одинаковый tag на обоих экранах связывает их
                child: AspectRatio(
                  aspectRatio: 16 / 9, // все превью одинаковой формы
                  child: Image.memory(
                    photo.bytes,
                    fit: BoxFit.cover,
                    cacheWidth: 800, // декодировать уменьшенную копию: экономит память в списке
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  photo.description.isEmpty
                      ? 'Без описания'
                      : photo.description,
                  maxLines: 2,
                  overflow: TextOverflow
                      .ellipsis, // обрезанный текст заканчивается на «…»
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'note_content.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/note_models.dart';

enum NoteMenuAction { edit, delete }

class NoteFocusMenu extends StatelessWidget {
  final Note note;

  // Положение исходной карточки на экране.
  final Rect sourceRect;

  // Была ли заметка раскрыта.
  final bool expanded;

  // Прогресс анимации от 0 до 1.
  final double progress;

  const NoteFocusMenu({
    super.key,
    required this.note,
    required this.sourceRect,
    required this.expanded,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);

        const horizontalMargin = 16.0;
        const gap = 12.0;
        const menuHeight = 112.0;

        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        final safeTop = media.padding.top + 12;
        final safeBottom =
            math.max(media.padding.bottom, media.viewInsets.bottom) + 12;

        // Ограничение размера, чтобы карточка и меню помещались даже у нижнего края экрана.
        final availableHeight = math.max(
          1.0,
          screenHeight - safeTop - safeBottom - menuHeight - gap,
        );

        final targetWidth = math.min(
          sourceRect.width * 1.04,
          screenWidth - horizontalMargin * 2,
        );

        final targetHeight = math.min(
          sourceRect.height * 1.04,
          availableHeight,
        );

        final targetLeft = (sourceRect.center.dx - targetWidth / 2)
            .clamp(
              horizontalMargin,
              screenWidth - horizontalMargin - targetWidth,
            )
            .toDouble();

        final maxTop =
            screenHeight - safeBottom - menuHeight - gap - targetHeight;

        final targetTop = (sourceRect.center.dy - targetHeight / 2)
            .clamp(safeTop, math.max(safeTop, maxTop))
            .toDouble();

        final targetRect = Rect.fromLTWH(
          targetLeft,
          targetTop,
          targetWidth,
          targetHeight,
        );

        // Перемещение и увеличение исходной карточки.
        final rect = Rect.lerp(sourceRect, targetRect, progress)!;

        // Кнопки показывается чуть позже карточки.
        final menuProgress = ((progress - 0.25) / 0.75)
            .clamp(0.0, 1.0)
            .toDouble();

        return Stack(
          children: [
            Positioned.fromRect(
              rect: rect,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                elevation: 4 + 16 * progress,
                shadowColor: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: NoteContent(note: note, expanded: expanded),
                ),
              ),
            ),

            // Меню находится рядом с карточкой — под ней.
            Positioned(
              left: targetRect.left,
              top: targetRect.bottom + gap,
              width: targetRect.width,
              height: menuHeight,
              child: IgnorePointer(
                ignoring: menuProgress < 1,
                child: Opacity(
                  opacity: menuProgress,
                  child: Transform.translate(
                    offset: Offset(0, 8 * (1 - menuProgress)),
                    child: Material(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Expanded(
                            child: ListTile(
                              leading: const Icon(Icons.edit_outlined),
                              title: const Text('Изменить'),
                              onTap: () {
                                Navigator.of(context).pop(NoteMenuAction.edit);
                              },
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              title: Text(
                                'Удалить',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context)
                                    .pop(NoteMenuAction.delete);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

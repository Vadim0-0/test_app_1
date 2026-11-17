import 'package:flutter/material.dart';

import '../models/note_models.dart';
import '../widgets/note_focus_menu.dart';

Future<NoteMenuAction?> showNoteFocusMenu(
  BuildContext context,
  BuildContext cardContext,
  Note note, {
  required bool expanded,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);

  final overlay = navigator.overlay;

  if (overlay == null) return null;

  final cardBox = cardContext.findRenderObject();
  final overlayBox = overlay.context.findRenderObject();

  if (cardBox is! RenderBox || overlayBox is! RenderBox) {
    return null;
  }

  // Координаты карточки относительно слоя Navigator.
  final position = cardBox.localToGlobal(Offset.zero, ancestor: overlayBox);

  final sourceRect = position & cardBox.size;

  final route = RawDialogRoute<NoteMenuAction>(
    barrierDismissible: true,
    barrierLabel: 'Закрыть меню заметки',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final progress = Curves.easeInOutCubic.transform(animation.value);

      return NoteFocusMenu(
        note: note,
        sourceRect: sourceRect,
        expanded: expanded,
        progress: progress,
      );
    },
  );

  final action = await navigator.push<NoteMenuAction>(route);
  await route.completed;
  return action;
}

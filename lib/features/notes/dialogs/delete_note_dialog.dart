import 'package:flutter/material.dart';

import '../models/note_models.dart';

Future<bool?> showDeleteNoteDialog(BuildContext context, Note note) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Удалить заметку?'),
        content: Text('Заметка «${note.title}» будет удалена.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Удалить'),
          ),
        ],
      );
    },
  );
}

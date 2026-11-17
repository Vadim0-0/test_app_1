import 'package:flutter/material.dart';

import '../models/note_models.dart';

Future<bool?> showDeleteCategoryDialog(
  BuildContext context,
  NoteCategory category,
  int notesCount,
) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Удалить категорию «${category.name}»?'),
        content: Text(
          'Заметок в категории: $notesCount.\n\n'
          'Можно сохранить их без категории или удалить '
          'вместе с категорией. Удаление заметок нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Сохранить заметки'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Удалить вместе с заметками'),
          ),
        ],
      );
    },
  );
}

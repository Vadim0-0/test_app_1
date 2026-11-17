import 'package:flutter/material.dart';

// Показывает окно "Удалить фото?" с кнопками "Да" и "Нет"
// Возвращает true, если нажали "Да"; false — "Нет" или закрыли окно.
Future<bool> confirmDelete(BuildContext context) async {
  final result = await showDialog<bool>(
    // Открывается окно поверх экрана и ждёт закрытия
    // <bool> - Значение которое оно возращает
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.delete_outline),
      title: const Text('Удалить фото?'),
      content: const Text(
        'Фото и описание будут удалены без возможностьи восстановления.',
      ),
      actions: [
        TextButton(
          // pop закрывает окно и возвращает значение туда, где ждут showDialog
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Нет'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Да'),
        ),
      ],
    ),
  );
  // Если тапнули мимо окна или нажали "Назад", result будет null.
  return result ?? false;
}

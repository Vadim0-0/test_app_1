import 'package:flutter/material.dart';

import '../models/note_models.dart';

/// Общие заголовок и текст для карточки и её копии в меню.
class NoteContent extends StatelessWidget {
  final Note note;
  final bool expanded;
  final bool animate;
  const NoteContent({
    super.key,
    required this.note,
    required this.expanded,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = expanded
        ? Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(note.text.isEmpty ? 'Без текста' : note.text),
          )
        : const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(note.title, style: Theme.of(context).textTheme.titleMedium),
        if (animate)
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: body,
          )
        else
          body,
      ],
    );
  }
}

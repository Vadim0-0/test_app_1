import 'note_content.dart';

import 'package:flutter/material.dart';

import '../models/note_models.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final bool expanded;
  final bool hidden;
  final VoidCallback onTap;
  final ValueChanged<BuildContext> onLongPress;
  const NoteCard({
    super.key,
    required this.note,
    required this.expanded,
    required this.hidden,
    required this.onTap,
    required this.onLongPress,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Builder(
        builder: (cardContext) {
          return Opacity(
            opacity: hidden ? 0 : 1,
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  onTap();
                },
                onLongPress: () {
                  onLongPress(cardContext);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: NoteContent(
                    note: note,
                    expanded: expanded,
                    animate: true,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

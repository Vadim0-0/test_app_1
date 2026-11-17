import 'package:flutter/material.dart';

import '../models/note_models.dart';

class NoteCategoryBar extends StatelessWidget {
  final List<NoteCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelected;
  final VoidCallback onAdd;
  final ValueChanged<NoteCategory> onEdit;
  const NoteCategoryBar({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
    required this.onAdd,
    required this.onEdit,
  });
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Все'),
            selected: selectedCategoryId == null,
            onSelected: (_) {
              onSelected(null);
            },
          ),
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onLongPress: () => onEdit(category),
                child: ChoiceChip(
                  avatar: CircleAvatar(
                    backgroundColor: Color(category.colorValue),
                    radius: 8,
                  ),
                  label: Text(category.name),
                  selected: selectedCategoryId == category.id,
                  onSelected: (_) {
                    onSelected(category.id);
                  },
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Добавить категорию',
            onPressed: onAdd,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

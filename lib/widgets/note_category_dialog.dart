import 'package:flutter/material.dart';

import '../models/note_models.dart';

enum CategoryDialogAction { delete }

class NoteCategoryDialog extends StatefulWidget {
  final NoteCategory? category;

  const NoteCategoryDialog({super.key, this.category});

  @override
  State<NoteCategoryDialog> createState() => _NoteCategoryDialogState();
}

class _NoteCategoryDialogState extends State<NoteCategoryDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late int _colorValue;

  static const _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.category?.name ?? '');

    _colorValue = widget.category?.colorValue ?? Colors.blue.toARGB32();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final category = NoteCategory(
      id:
          widget.category?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      colorValue: _colorValue,
    );

    Navigator.of(context).pop(category);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.category != null;

    return AlertDialog(
      title: Text(editing ? 'Изменить категорию' : 'Новая категория'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                readOnly: editing,
                maxLength: 30,
                decoration: const InputDecoration(labelText: 'Название'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Цвет категории'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final color in _colors)
                    Semantics(
                      button: true,
                      label: 'Цвет ${_colors.indexOf(color) + 1}',
                      selected: color.toARGB32() == _colorValue,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _colorValue = color.toARGB32();
                          });
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: color.toARGB32() == _colorValue
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (editing)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop(CategoryDialogAction.delete);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Удалить категорию'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(onPressed: _save, child: const Text('Сохранить')),
      ],
    );
  }
}

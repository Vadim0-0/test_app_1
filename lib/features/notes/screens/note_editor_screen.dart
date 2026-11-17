import 'package:flutter/material.dart';

import '../models/note_models.dart';

import '../../../shared/widgets/animated_dropdown.dart';

class NoteEditorScreen extends StatefulWidget {
  final List<NoteCategory> categories;
  final Note? note;

  const NoteEditorScreen({super.key, required this.categories, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _textController;

  // Пустая строка — пункт «Без категории» в селекторе.
  late String _categoryId;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.note?.title ?? '');

    _textController = TextEditingController(text: widget.note?.text ?? '');

    _categoryId = widget.note?.categoryId ?? '';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final result = Note(
      id: widget.note?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      text: _textController.text.trim(),
      categoryId: _categoryId.isEmpty ? null : _categoryId,
    );

    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.note != null;

    final categoryLabels = <String, String>{
      '': 'Без категории — только во «Все»',
      for (final category in widget.categories) category.id: category.name,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Изменить заметку' : 'Новая заметка'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AnimatedDropdown<String>(
                label: 'Категория',
                value: _categoryId,
                items: categoryLabels.keys.toList(),
                labelOf: (id) => categoryLabels[id] ?? 'Без категории',
                onChanged: (id) {
                  setState(() {
                    _categoryId = id;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Заголовок',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите заголовок';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _textController,
                minLines: 10,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Текст заметки',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(editing ? 'Сохранить' : 'Создать'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

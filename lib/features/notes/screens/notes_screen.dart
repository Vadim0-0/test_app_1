import '../widgets/note_card.dart';
import '../widgets/note_category_bar.dart';

import 'package:flutter/material.dart';

import '../models/note_models.dart';

import '../controllers/notes_controller.dart';
import '../dialogs/delete_note_dialog.dart';
import '../dialogs/delete_category_dialog.dart';
import '../dialogs/show_note_focus_menu.dart';

import '../dialogs/note_category_dialog.dart';
import '../widgets/note_focus_menu.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _controller = NotesController();
  final _expandedIds = <String>{};
  String? _focusedNoteId;

  List<NoteCategory> get _categories => _controller.categories;
  List<Note> get _notes => _controller.notes;
  String? get _selectedCategoryId => _controller.selectedCategoryId;
  bool get _loading => _controller.loading;
  bool get _saving => _controller.saving;
  String? get _loadError => _controller.loadError;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.load();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {
      _expandedIds.removeWhere((id) => !_notes.any((note) => note.id == id));
    });
  }

  Future<void> _load() => _controller.load();

  void _showSaveResult(NotesSaveResult result) {
    if (!mounted) return;
    final message = switch (result) {
      NotesSaveResult.failed =>
        'Не удалось сохранить изменения. Изменения не применены.',
      NotesSaveResult.duplicateCategory =>
        'Категория с таким названием уже есть',
      _ => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Color? get _selectedColor {
    for (final category in _categories) {
      if (category.id == _selectedCategoryId) {
        return Color(category.colorValue);
      }
    }

    return null;
  }

  List<Note> get _visibleNotes => _controller.visibleNotes;

  Future<void> _openCategoryDialog({NoteCategory? category}) async {
    final result = await showDialog<Object>(
      context: context,
      builder: (_) => NoteCategoryDialog(category: category),
    );

    if (!mounted || result == null) return;

    // Пользователь нажал «Удалить категорию».
    if (result == CategoryDialogAction.delete) {
      if (category != null) {
        await _confirmDeleteCategory(category);
      }
      return;
    }

    if (result is! NoteCategory) return;

    _showSaveResult(await _controller.saveCategory(result));
  }

  Future<void> _openEditor([Note? note]) async {
    final result = await Navigator.of(context).push<Note>(
      MaterialPageRoute(
        builder: (_) =>
            NoteEditorScreen(categories: List.of(_categories), note: note),
      ),
    );

    if (!mounted || result == null) return;

    _showSaveResult(await _controller.saveNote(result));
  }

  Future<void> _showNoteActions(Note note, BuildContext cardContext) async {
    if (_focusedNoteId != null) return;

    setState(() => _focusedNoteId = note.id);
    NoteMenuAction? action;
    try {
      action = await showNoteFocusMenu(
        context,
        cardContext,
        note,
        expanded: _expandedIds.contains(note.id),
      );
    } finally {
      if (mounted) setState(() => _focusedNoteId = null);
    }

    if (!mounted || action == null) return;

    switch (action) {
      case NoteMenuAction.edit:
        await _openEditor(note);
        break;

      case NoteMenuAction.delete:
        await _deleteNote(note);
        break;
    }
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDeleteNoteDialog(context, note);

    if (!mounted || confirmed != true) return;

    _showSaveResult(await _controller.deleteNote(note.id));
  }

  Future<void> _confirmDeleteCategory(NoteCategory category) async {
    final notesCount = _notes
        .where((note) => note.categoryId == category.id)
        .length;

    final deleteNotes = await showDeleteCategoryDialog(
      context,
      category,
      notesCount,
    );

    // Именно null означает отмену.
    // false — полноценный выбор «сохранить заметки».
    if (!mounted || deleteNotes == null) return;

    _showSaveResult(
      await _controller.deleteCategory(category.id, deleteNotes: deleteNotes),
    );
  }

  Widget _buildNotes() {
    final notes = _visibleNotes;

    if (notes.isEmpty) {
      return Center(
        child: Text(
          _selectedCategoryId == null
              ? 'Заметок пока нет. Нажмите +'
              : 'В этой категории пока нет заметок',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final expanded = _expandedIds.contains(note.id);

        return NoteCard(
          key: ValueKey(note.id),
          note: note,
          expanded: expanded,
          hidden: _focusedNoteId == note.id,
          onTap: () => setState(() {
            if (expanded) {
              _expandedIds.remove(note.id);
            } else {
              _expandedIds.add(note.id);
            }
          }),
          onLongPress: (cardContext) => _showNoteActions(note, cardContext),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surface;
    final categoryColor = _selectedColor;

    final backgroundColor = categoryColor == null
        ? baseColor
        : Color.alphaBlend(categoryColor.withValues(alpha: 0.12), baseColor);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Заметки'),
        backgroundColor: backgroundColor,
      ),
      floatingActionButton: _loading || _loadError != null
          ? null
          : FloatingActionButton(
              onPressed: _saving ? null : () => _openEditor(),
              tooltip: 'Добавить заметку',
              child: const Icon(Icons.add),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadError!),
                  TextButton(onPressed: _load, child: const Text('Повторить')),
                ],
              ),
            )
          : AbsorbPointer(
              absorbing: _saving,
              child: Column(
                children: [
                  NoteCategoryBar(
                    categories: _categories,
                    selectedCategoryId: _selectedCategoryId,
                    onSelected: _controller.selectCategory,
                    onAdd: () => _openCategoryDialog(),
                    onEdit: (category) =>
                        _openCategoryDialog(category: category),
                  ),
                  if (_saving) const LinearProgressIndicator(),
                  Expanded(child: _buildNotes()),
                ],
              ),
            ),
    );
  }
}

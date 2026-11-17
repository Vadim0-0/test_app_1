import 'package:flutter/material.dart';

import '../models/note_models.dart';
import '../services/notes_storage.dart';
import '../widgets/note_category_dialog.dart';
import '../widgets/note_focus_menu.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _storage = NotesStorage();

  List<NoteCategory> _categories = [];
  List<Note> _notes = [];

  // null — выбрано «Все».
  String? _selectedCategoryId;

  // Раскрытая заметка по ID
  final _expandedIds = <String>{};

  String? _focusedNoteId;

  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final data = await _storage.load();

      if (!mounted) return;

      setState(() {
        _categories = data.categories;
        _notes = data.notes;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadError = 'Не удалось загрузить заметки';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveData({
    required List<NoteCategory> categories,
    required List<Note> notes,
  }) async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      await _storage.save(NotesData(categories: categories, notes: notes));

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _notes = notes;

        final selectedCategoryExists = categories.any(
          (category) => category.id == _selectedCategoryId,
        );

        if (!selectedCategoryExists) {
          _selectedCategoryId = null;
        }

        _expandedIds.removeWhere((id) => !notes.any((note) => note.id == id));
      });
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не удалось сохранить изменения. '
            'Изменения не применены.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Color? get _selectedColor {
    for (final category in _categories) {
      if (category.id == _selectedCategoryId) {
        return Color(category.colorValue);
      }
    }

    return null;
  }

  List<Note> get _visibleNotes {
    if (_selectedCategoryId == null) {
      return _notes;
    }

    return _notes.where((note) {
      return note.categoryId == _selectedCategoryId;
    }).toList();
  }

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

    final updated = List<NoteCategory>.of(_categories);

    final index = updated.indexWhere((item) => item.id == result.id);

    if (index == -1) {
      final duplicateName = updated.any(
        (item) => item.name.toLowerCase() == result.name.toLowerCase(),
      );

      if (duplicateName) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Категория с таким названием уже есть')),
        );
        return;
      }

      updated.add(result);
    } else {
      updated[index] = result;
    }

    await _saveData(categories: updated, notes: List.of(_notes));
  }

  Future<void> _openEditor([Note? note]) async {
    final result = await Navigator.of(context).push<Note>(
      MaterialPageRoute(
        builder: (_) =>
            NoteEditorScreen(categories: List.of(_categories), note: note),
      ),
    );

    if (!mounted || result == null) return;

    final updated = List<Note>.of(_notes);

    final index = updated.indexWhere((item) => item.id == result.id);

    if (index == -1) {
      // Новая заметка появляется первой.
      updated.insert(0, result);
    } else {
      // При редактировании сохраняется прежний ID.
      updated[index] = result;
    }

    await _saveData(categories: List.of(_categories), notes: updated);
  }

  Future<void> _showNoteActions(Note note, BuildContext cardContext) async {
    if (_focusedNoteId != null) return;

    final navigator = Navigator.of(context, rootNavigator: true);

    final overlay = navigator.overlay;

    if (overlay == null) return;

    final cardBox = cardContext.findRenderObject();
    final overlayBox = overlay.context.findRenderObject();

    if (cardBox is! RenderBox || overlayBox is! RenderBox) {
      return;
    }

    // Координаты карточки относительно слоя Navigator.
    final position = cardBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    final sourceRect = position & cardBox.size;

    final expanded = _expandedIds.contains(note.id);

    setState(() {
      _focusedNoteId = note.id;
    });

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

    NoteMenuAction? action;

    try {
      action = await navigator.push<NoteMenuAction>(route);

      // Одижание окончания обратной анимации, прежде чем возвращать исходную карточку и открывать редактор.
      await route.completed;
    } finally {
      if (mounted) {
        setState(() {
          _focusedNoteId = null;
        });
      }
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
    final confirmed = await showDialog<bool>(
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

    if (!mounted || confirmed != true) return;

    final updated = _notes.where((item) => item.id != note.id).toList();

    await _saveData(categories: List.of(_categories), notes: updated);
  }

  Future<void> _confirmDeleteCategory(NoteCategory category) async {
    final notesCount = _notes
        .where((note) => note.categoryId == category.id)
        .length;

    // false — сохранить заметки.
    // true — удалить заметки.
    // null — отмена.
    final deleteNotes = await showDialog<bool>(
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

    // Именно null означает отмену.
    // false — полноценный выбор «сохранить заметки».
    if (!mounted || deleteNotes == null) return;

    final updatedCategories = _categories
        .where((item) => item.id != category.id)
        .toList();

    final List<Note> updatedNotes;

    if (deleteNotes) {
      // Удаляем только заметки выбранной категории.
      updatedNotes = _notes
          .where((note) => note.categoryId != category.id)
          .toList();
    } else {
      // Сохраняем заметки, убирая связь с категорией.
      updatedNotes = _notes.map((note) {
        if (note.categoryId != category.id) {
          return note;
        }

        return Note(
          id: note.id,
          title: note.title,
          text: note.text,
          categoryId: null,
        );
      }).toList();
    }

    await _saveData(categories: updatedCategories, notes: updatedNotes);
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Все'),
            selected: _selectedCategoryId == null,
            onSelected: (_) {
              setState(() {
                _selectedCategoryId = null;
              });
            },
          ),
          for (final category in _categories)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onLongPress: () => _openCategoryDialog(category: category),
                child: ChoiceChip(
                  avatar: CircleAvatar(
                    backgroundColor: Color(category.colorValue),
                    radius: 8,
                  ),
                  label: Text(category.name),
                  selected: _selectedCategoryId == category.id,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategoryId = category.id;
                    });
                  },
                ),
              ),
            ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Добавить категорию',
            onPressed: () => _openCategoryDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
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

        return Padding(
          key: ValueKey(note.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: Builder(
            builder: (cardContext) {
              return Opacity(
                opacity: _focusedNoteId == note.id ? 0 : 1,
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (expanded) {
                          _expandedIds.remove(note.id);
                        } else {
                          _expandedIds.add(note.id);
                        }
                      });
                    },
                    onLongPress: () {
                      _showNoteActions(note, cardContext);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            note.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: expanded
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(
                                      note.text.isEmpty
                                          ? 'Без текста'
                                          : note.text,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
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
                  _buildCategories(),
                  if (_saving) const LinearProgressIndicator(),
                  Expanded(child: _buildNotes()),
                ],
              ),
            ),
    );
  }
}

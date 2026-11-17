import 'package:flutter/foundation.dart';

import '../data/notes_storage.dart';
import '../models/note_models.dart';

enum NotesSaveResult { saved, busy, failed, duplicateCategory }

class NotesController extends ChangeNotifier {
  NotesController({NotesStorage? storage})
    : _storage = storage ?? NotesStorage();
  final NotesStorage _storage;
  List<NoteCategory> _categories = [];
  List<Note> _notes = [];
  List<NoteCategory> get categories => List.unmodifiable(_categories);
  List<Note> get notes => List.unmodifiable(_notes);
  String? _selectedCategoryId;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  List<Note> get visibleNotes => _selectedCategoryId == null
      ? notes
      : _notes.where((note) => note.categoryId == _selectedCategoryId).toList();

  void selectCategory(String? id) {
    _selectedCategoryId = id;
    _notify();
  }

  Future<void> load() async {
    _loading = true;
    _loadError = null;
    _notify();
    try {
      final data = await _storage.load();
      if (_disposed) return;
      _categories = List.of(data.categories);
      _notes = List.of(data.notes);
    } catch (_) {
      if (!_disposed) _loadError = 'Не удалось загрузить заметки';
    } finally {
      _loading = false;
      _notify();
    }
  }

  Future<NotesSaveResult> _save(
    List<NoteCategory> categories,
    List<Note> notes,
  ) async {
    if (_saving || _loading || _loadError != null || _disposed) {
      return NotesSaveResult.busy;
    }
    _saving = true;
    _notify();
    try {
      await _storage.save(NotesData(categories: categories, notes: notes));
      if (_disposed) return NotesSaveResult.saved;
      _categories = categories;
      _notes = notes;
      if (!categories.any((category) => category.id == _selectedCategoryId)) {
        _selectedCategoryId = null;
      }
      return NotesSaveResult.saved;
    } catch (_) {
      return NotesSaveResult.failed;
    } finally {
      _saving = false;
      _notify();
    }
  }

  Future<NotesSaveResult> saveNote(Note note) {
    final updated = List<Note>.of(_notes);
    final index = updated.indexWhere((item) => item.id == note.id);
    if (index == -1) {
      updated.insert(0, note);
    } else {
      updated[index] = note;
    }
    return _save(List.of(_categories), updated);
  }

  Future<NotesSaveResult> saveCategory(NoteCategory category) {
    final updated = List<NoteCategory>.of(_categories);
    final index = updated.indexWhere((item) => item.id == category.id);
    if (updated.any(
      (item) =>
          item.id != category.id &&
          item.name.toLowerCase() == category.name.toLowerCase(),
    )) {
      return Future.value(NotesSaveResult.duplicateCategory);
    }
    if (index == -1) {
      updated.add(category);
    } else {
      updated[index] = category;
    }
    return _save(updated, List.of(_notes));
  }

  Future<NotesSaveResult> deleteNote(String id) => _save(
    List.of(_categories),
    _notes.where((note) => note.id != id).toList(),
  );

  Future<NotesSaveResult> deleteCategory(
    String id, {
    required bool deleteNotes,
  }) {
    final categories = _categories
        .where((category) => category.id != id)
        .toList();
    final notes = deleteNotes
        ? _notes.where((note) => note.categoryId != id).toList()
        : _notes
              .map(
                (note) => note.categoryId != id
                    ? note
                    : Note(
                        id: note.id,
                        title: note.title,
                        text: note.text,
                        categoryId: null,
                      ),
              )
              .toList();
    return _save(categories, notes);
  }

  String? get selectedCategoryId => _selectedCategoryId;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get loadError => _loadError;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:test_app_1/features/notes/controllers/notes_controller.dart';
import 'package:test_app_1/features/notes/data/notes_storage.dart';
import 'package:test_app_1/features/notes/models/note_models.dart';

class MemoryNotesStorage implements NotesStorage {
  NotesData data = const NotesData(
    categories: [NoteCategory(id: 'work', name: 'Работа', colorValue: 0)],
    notes: [
      Note(id: '1', title: 'Первая', text: '', categoryId: 'work'),
      Note(id: '2', title: 'Вторая', text: ''),
    ],
  );
  bool failSave = false;
  @override
  Future<NotesData> load() async => data;
  @override
  Future<void> save(NotesData value) async {
    if (failSave) throw StateError('Write failed');
    data = value;
  }
}

void main() {
  late MemoryNotesStorage storage;
  late NotesController controller;
  setUp(() async {
    storage = MemoryNotesStorage();
    controller = NotesController(storage: storage);
    await controller.load();
  });
  tearDown(() => controller.dispose());

  test('Удаление категории сохраняет заметки без категории', () async {
    controller.selectCategory('work');
    expect(
      await controller.deleteCategory('work', deleteNotes: false),
      NotesSaveResult.saved,
    );
    expect(controller.categories, isEmpty);
    expect(controller.notes, hasLength(2));
    expect(controller.notes.first.categoryId, isNull);
    expect(controller.selectedCategoryId, isNull);
    expect(storage.data.notes.first.categoryId, isNull);
  });

  test('Удаление вместе с категорией не затрагивает другие заметки', () async {
    await controller.deleteCategory('work', deleteNotes: true);
    expect(controller.notes.map((note) => note.id), ['2']);
  });

  test('Ошибка записи сохраняет прежнее состояние', () async {
    storage.failSave = true;
    expect(await controller.deleteNote('1'), NotesSaveResult.failed);
    expect(controller.notes, hasLength(2));
    expect(controller.saving, isFalse);
  });

  test('Имена категорий сравниваются без учёта регистра', () async {
    expect(
      await controller.saveCategory(
        const NoteCategory(id: 'other', name: 'работа', colorValue: 1),
      ),
      NotesSaveResult.duplicateCategory,
    );
    expect(controller.categories, hasLength(1));
  });
}

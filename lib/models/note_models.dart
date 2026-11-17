class NoteCategory {
  final String id;
  final String name;

  // Cохранение цвета как целое число ARGB.
  final int colorValue;

  const NoteCategory({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
  };

  factory NoteCategory.fromJson(Map<String, dynamic> json) {
    return NoteCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: (json['colorValue'] as num).toInt(),
    );
  }
}

class Note {
  final String id;
  final String title;
  final String text;

  // null означает «Без категории».
  final String? categoryId;

  const Note({
    required this.id,
    required this.title,
    required this.text,
    this.categoryId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'text': text,
    'categoryId': categoryId,
  };

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
      categoryId: json['categoryId'] as String?,
    );
  }
}

class NotesData {
  final List<NoteCategory> categories;
  final List<Note> notes;

  const NotesData({required this.categories, required this.notes});

  Map<String, dynamic> toJson() => {
    'categories': categories.map((item) => item.toJson()).toList(),
    'notes': notes.map((item) => item.toJson()).toList(),
  };

  factory NotesData.fromJson(Map<String, dynamic> json) {
    return NotesData(
      categories: (json['categories'] as List<dynamic>)
          .map((item) => NoteCategory.fromJson(item as Map<String, dynamic>))
          .toList(),
      notes: (json['notes'] as List<dynamic>)
          .map((item) => Note.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

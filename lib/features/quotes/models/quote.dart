// Модель цитаты
class Quote {
  final String text;
  final String author;

  const Quote(this.text, this.author);

  // Фабричный конструктор
  // Обычный коструктор сам заполняет аоля, а фаьричный может выполнить люьой код и вернуть объект. В данном случае, достаёт из Map значения по ключам и передаёт их в обычный конструктор
  // Map<String, dynamic>: ключи — строки, значения — что угодно (JSON может содержать строки, числа, списки).
  //as String говорит Dart: «я уверен, что тут строка». Если там окажется не строка, будет ошибка.
  factory Quote.fromJson(Map<String, dynamic> json) =>
      Quote(json['text'] as String, json['author'] as String);
}

// Описание одной задачи
class Todo {
  final int id;
  String title;
  bool done;

  // Конструктор принимает только текст.

  // this.title кладёт аргумент сразу в поле.
  // : после скобок — это список инициализации: поля заполняются до того, как объект будет готов. Так обязательно задают final-поля, которые не приходят аргументом.
  // id = DateTime.now().microsecondsSinceEpoch — количество микросекунд с 1 января 1970 года. Получается большое число, разное для каждой задачи. Это простой способ сделать уникальный id.
  // done = false — новая задача не выполнена.
  Todo(this.title) : id = DateTime.now().microsecondsSinceEpoch, done = false;

  // Второй (именованный) конструктор: собирает задачу из сохранённых данных.
  Todo.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      title = json['title'] as String,
      done = json['done'] as bool;

  // Превращает задачу в Map, который легко перевести в JSON.
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};
}

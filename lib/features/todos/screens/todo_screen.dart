import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../data/todos_storage.dart';

// Виджет
class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

// Состояние
class _TodoScreenState extends State<TodoScreen> {
  // Список задач
  final List<Todo> _todos = [];

  // Контроллер поля ввода, через него читаем и очищаем текст.
  final _controller = TextEditingController();

  // Хранит изменяемый текст
  final _editController = TextEditingController();
  // Позволяет передать фокус полю и открыть клавиатуру
  final _editFocusNode = FocusNode();

  // Содержит id задачи, которая сейчас редактируется
  int? _editingTodoId;

  @override
  void dispose() {
    _controller.dispose();
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  final _storage = TodosStorage();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final todos = await _storage.load();
    if (!mounted) return;
    setState(() => _todos.addAll(todos));
  }

  Future<void> _save() => _storage.save(_todos);

  // Меняет данные, перерисовывает экран и сразу сохраняет.
  void _update(VoidCallback change) {
    setState(change);
    _save();
  }

  // Добавление задачи
  void _add() {
    //Берём текст из поля.
    //.trim() убирает пробелы в начале и конце
    final text = _controller.text.trim();

    // Если пусто, ничего не делать
    if (text.isEmpty) return;

    // Создание задачи, добавление в конец списка и перерисовывание экрана
    _update(() => _todos.add(Todo(text)));

    // Отчищение поля для следующей задачи
    _controller.clear();
  }

  // Удаление с отменой
  void _remove(Todo todo) {
    // Запоминает, на какой пизиции была задача, чтобы при отмене вернуть её на тоже место
    final index = _todos.indexOf(todo);

    // Удаление из списка
    _update(() => _todos.remove(todo));

    // служьа, которая показывает всплывающие плашки (SnackBar) внизу экрана
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        // Текст плашки
        content: Text('Удалено: ${todo.title}'),

        // Кнопка на плашке. При нажатии, кдалённый элемент  возращается обратно на позицию index. У объекта сохранился id, поэтому для Flutter это та же самая задача.
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () {
            if (!mounted) return; // экран уже закрыт — ничего не делаем
            _update(() => _todos.insert(index, todo));
          },
        ),
      ),
    );
  }

  // Начало Редактирования
  void _startEditing(Todo todo) {
    // Копирование текущее название
    _editController.text = todo.title;
    // Выделение всего текста
    _editController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _editController.text.length,
    );

    // Перестраивание строки: вместо Text появляется TextField.
    setState(() {
      _editingTodoId = todo.id;
    });

    // После построения нового кадра поле получает фокус, открывается клавиатура.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editingTodoId == todo.id) {
        _editFocusNode.requestFocus();
      }
    });
  }

  // Завершение редактирования
  void _finishEditing(Todo todo) {
    if (_editingTodoId != todo.id) return;

    final newTitle = _editController.text.trim();

    _editFocusNode.unfocus();

    _update(() {
      if (newTitle.isNotEmpty) {
        todo.title = newTitle;
      }

      _editingTodoId = null;
    });
  }

  // Отрисовка
  @override
  Widget build(BuildContext context) {
    // Считывает выполненные задачи:
    // .where(...) оставляет только те элементы, для которых условие истинно;
    // (t) => t.done — условие «задача выполнена»;
    // .length — сколько их осталось.
    final doneCount = _todos.where((t) => t.done).length;

    return Scaffold(
      // В заголовке отображается прогресс
      appBar: AppBar(title: Text('To-Do ($doneCount/${_todos.length})')),

      // Колонка из двух частей: сверху поле ввода, ниже список.
      body: Column(
        children: [
          Padding(
            // Отступ 16 и строка: поле и кнопка рядом.
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Expanded внутри Row отдаёт полю всю ширину, которую не заняла кнопка. Без него TextField в Row выдаёт ошибку, потому что не знает своей ширины.
                Expanded(
                  child: TextField(
                    // hintText — серая подсказка внутри пустого поля. Когда начинаете печатать, она исчезает. В отличие от labelText в конвертере, она не «всплывает» наверх.
                    // Здесь const можно поставить, потому что ничего не меняется.
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Новая задача',
                      border: OutlineInputBorder(),
                    ),

                    // onSubmitted срабатывает, когда нажали Enter или «Готово» на клавиатуре.
                    onSubmitted: (_) => _add(),
                  ),
                ),

                // Промежуток 8 и круглая залитая кнопка +. IconButton.filled — именованный конструктор
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _add, icon: const Icon(Icons.add)),
              ],
            ),
          ),

          // Спислк задач

          // Expanded отдаёт списку всё оставшееся мест
          // ListView.builder строит только видимые строки.
          Expanded(
            child: ListView.builder(
              // Для каждой позиции берётся своя задача
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];

                // Dismissible — обёртка, которая позволяет смахнуть строку свайпом.
                return Dismissible(
                  // Ключ обязателен. После удаления строки сдвигаются, и по ключу Flutter понимает, какая именно строка ушла. Если бы ключом был index, после удаления первой строки вторая получила бы её номер, и Flutter перепутал бы их. Отсюда ошибка «A dismissed Dismissible widget is still part of the tree». Поэтому и нужен стабильный id.
                  key: ValueKey(todo.id),
                  // Свайп разрешён только справа налево. endToStart значит «от конца строки к началу». В языках с письмом справа налево (арабский) направление автоматически зеркалится.
                  direction: DismissDirection.endToStart,

                  // Что видно под строкой во время свайпа: красный фон и белая корзина, прижатая вправо с отступом
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  //Строку смахнули до конца, вызываем удаление. Аргумент (направление свайпа) не нужен, поэтому _.
                  onDismissed: (_) => _remove(todo),

                  child: ListTile(
                    leading: Checkbox(
                      value: todo.done,

                      // Нажатие на чекбокс для изменения состояния задачи
                      onChanged: (value) {
                        _update(() => todo.done = value ?? false);
                      },
                    ),

                    title: _editingTodoId == todo.id
                        // Редактирование задачи
                        ? TextField(
                            controller: _editController,
                            focusNode: _editFocusNode,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),

                            // Нажатие на готово, сохранятеся новое название, в места поля появляется просто текст
                            onSubmitted: (_) => _finishEditing(todo),
                            // Нажатие вне поля, сохранятеся новое название, в места поля появляется просто текст
                            onTapOutside: (_) => _finishEditing(todo),
                          )
                        // Обычное поле(Обработчик нажатия на текст)
                        : GestureDetector(
                            // нажатие внутри прямоугольной области GestureDetector считается попаданием по нему;
                            // нажатие не передаётся виджетам, которые находятся визуально позади него.
                            behavior: HitTestBehavior.opaque,

                            // Нажатие на текст, поле с текстом изменяется на поле ввода, текст выделяется
                            onTap: () => _startEditing(todo),
                            child: Text(
                              todo.title,
                              style: TextStyle(
                                decoration: todo.done
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: todo.done ? Colors.grey : null,
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

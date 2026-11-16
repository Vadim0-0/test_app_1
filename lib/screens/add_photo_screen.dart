import 'dart:typed_data'; // тип Uint8List для байтов картинки

import 'package:flutter/material.dart'; // Все материал виджеты
import 'package:image_picker/image_picker.dart'; //
import 'package:path/path.dart'
    as p; // p.extension — достать ".jpg" из имени файла

import '../models/photo_entry.dart';

// Экран меняется (фото выбрано или нет, идёт ли загрузка), поэтому Stateful
class AddPhotoScreen extends StatefulWidget {
  const AddPhotoScreen({
    super.key,
  }); // const-конструктор. Fluttter может переисполльзовать виджет

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState(); // Объект, который хранит состояние
}

class _AddPhotoScreenState extends State<AddPhotoScreen> {
  final _picker =
      ImagePicker(); // Объект пакета, через него вызывается галерея/камера
  final _controller =
      TextEditingController(); // доступ к тексту в поле описания

  Uint8List? _bytes; // Байты выбранного фото; null - фото ещё не выбрано
  bool _picking =
      false; // true - идёт выбор/чтение файла. Для отображения спинера
  String _extension = '.jpg'; // расширение выбранного файла, по умолчанию .jpg

  // dispose() — метод, который Flutter вызывает, когда экран закрывается навсегда. Чтобы не было утечки памяти
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Выюо фото. source - откуда: ImageSource.gallery или ImageSource.camera
  // async, потому что пользователь выбирает фото некоторое неопределённое время
  Future<void> _pick(ImageSource source) async {
    setState(() => _picking = true); // пременной _picking задать true, значит идёт загрузка, отобразить индикатор

    try {
      final XFile? file = await _picker.pickImage(
        // Открывается системное окно для выбора фото и ожидаем результата
        source: source, // галерея или камера
        maxWidth: 2000, // уменьшение огромных фотографий
        imageQuality: 85, // сжытие
      );

      if (file == null) return; // Файлы не выбраны, окно закрыто
      final bytes = await file
          .readAsBytes(); // Чтение соледжимого файла в памяти
      if (!mounted) return; // Выход, если во время ожидания был закрыт экран
      setState(() {
        _bytes = bytes;
        // file.name — имя файла, например "IMG_0042.png".
        // p.extension вернёт ".png"; toLowerCase — на случай ".JPG".
        final ext = p.extension(file.name).toLowerCase();
        _extension = ext.isEmpty ? '.jpg' : ext;
      }); // Сохранение фото
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        // Плашка с ошибкой, внизу экрана
        SnackBar(content: Text('Не удалось загругрузить фото: $e')),
      );
    } finally {
      if (mounted)
        setState(() => _picking = false); // Отключение идикатора загрузки
    }
  }

  // Сохранение: собираем запись и возвращаем её предыдущему экрану.
  void _save() {
    final bytes = _bytes;
    if (bytes == null) return;
    final entry = PhotoEntry(
      bytes: bytes,
      description: _controller.text.trim(),
      extension: _extension,
    );
    Navigator.pop(
      context,
      entry,
    ); // После сохранения, возврат на предыдущий экран c передачей значения
  }

  // Отрисовка. Описание того, как должен выглядеть экран
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      // Каркас экрана
      appBar: AppBar(title: const Text('Новое фото')),
      body: SingleChildScrollView(
        // ПРокрутка: при открытой клавиатуре всё должно помещаться
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            AspectRatio(
              // Блок ч фиксированным соотношением сторон
              aspectRatio: 4 / 3, // Ширина : высота
              child: ClipRRect(
                // Обрезает содержимое по скругённым краям
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  // фон
                  color: colors.surfaceContainerHighest,
                  child: _buildPreview(colors), // Содержимое
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  // Бдок занимает половину ширины
                  child: OutlinedButton.icon(
                    // Кнопка с рамкой, иконкой и текстом
                    onPressed: _picking
                        ? null
                        : () => _pick(ImageSource.gallery), // Пока идёт выбор, кнопка остаётся неактивной, после тановится активной и открывает галерею
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Галерея'),
                  ),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    // Кнопка с рамко иконкой и текстом
                    onPressed: _picking ? null : () => _pick(ImageSource.camera), // Пока идёт выбор, кнопка остаётся неактивной, после тановится активной и открывает галерею
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Камера'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              // полк для ввода описания
              controller: _controller,
              minLines: 2, // минимальная высота поля
              maxLines: 5, // Максимальная высота поля
              textCapitalization: TextCapitalization
                  .sentences, // Заглавная буква в начале предложения
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Что на этой фотографии?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              // Кнопка с фоном
              onPressed: _bytes == null
                  ? null
                  : _save, // активна только когда фото выбрано
              icon: const Icon(Icons.check),
              label: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  // Что показывать в рамке превью: спиннер, заглушку или само фото.
  Widget _buildPreview(ColorScheme colors) {
    if (_picking) {
      return const Center(child: CircularProgressIndicator());
    }

    final bytes = _bytes; // Локальная копия для проверки на null

    if (bytes == null) {
      return Icon(
        Icons.add_photo_alternate_outlined,
        size: 64,
        color: colors.onSurfaceVariant,
      );
    }
    return Image.memory(
      // Если не null, тоотображать картинку
      bytes,
      fit: BoxFit.cover, // заполнить рамку целиком, лишнее обрезать
    );
  }
}

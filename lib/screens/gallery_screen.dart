import 'dart:convert';

import 'package:flutter/material.dart'; // Material-виджеты

import '../models/photo_entry.dart'; // модель
import 'add_photo_screen.dart'; // экран добавления
import 'photo_detail_screen.dart'; // экран просмотра

import '../services/photo_storage.dart'; // сохранение альбома
import '../widgets/confirm_delete_dialog.dart'; // Окно для подтверждения удаления

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final List<PhotoEntry> _photos = []; // Добавленные фото
  final _storage = PhotoStorage(); // работа с диском
  bool _loading = true; // true — альбом ещё загружается
  OverlayEntry? _deleteButtonEntry; // Элемент, который моржно вставить в Overlay поверх экрана, ссылка нужна, чтобы позже удалить кнопку

  // Загрузка при открытии экрана
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final photos = await _storage.load();
      if (!mounted) return;
      setState(() => _photos.addAll(photos));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось загрузить альбом: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Открыть экран добавления и дождаться, что он вернётся
  Future<void> _openAddScreen() async {
    final result = await Navigator.push<PhotoEntry>(
      // <PhotoEntry> - тип значения, которое должно вернуться
      context,
      MaterialPageRoute(
        builder: (_) => const AddPhotoScreen(), // Какой экран открыть
      ),
    );
    if (result == null || !mounted) return;

    try {
      //1) СНАЧАЛА файл: если запись не удалась, в списке не будет "битой" записи.
      await _storage.saveFile(result);
      if (!mounted) return;

      // 2) Потом список на экране
      setState(() => _photos.insert(0, result)); // Новое фото в начало

      // 3) ...и список описаний в prefs.
      await _storage.saveList(_photos);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось сохранить фото: $e')));
    }
  }

  // Открыть экран просмотра конкретного фото
  void _openDetail(PhotoEntry photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoDetailScreen(
          photo: photo,
        ), // Передача фото через конструктор экрана
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Фотоальбом. ${_photos.length} - фотографий')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Отображение загрузки
          : _photos.isEmpty
          ? _buildEmpty(context) // если список пуст, то отобразить заглушку
          : _buildList(), // Если не пуст, то отобразить фотографии
      floatingActionButton: FloatingActionButton(
        // круглая плавающая кнопка справа внизу
        onPressed: _openAddScreen,
        tooltip: 'Добавить фото', // подсказка при долгом нажатии / наведении
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  // Заглушка для пустого альюома
  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Колонка высотой содержимого внутри
        children: [
          Icon(
            Icons.photo_album_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text('Фотографий нет'),
          const SizedBox(height: 4),
          const Text('Нажмите «+», чтобы добавить'),
        ],
      ),
    );
  }

  // Список фотографий
  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        88,
      ), // снизу 88, чтобы FAB не закрывал последнюю карточку
      itemCount: _photos.length, // ко-во фотографий
      itemBuilder: (context, index) {
        // Вызывается для каждого видимого элемента
        final photo = _photos[index]; // Текущая запись

        return Card(
          clipBehavior: Clip.antiAlias, // обрезать содержимое (фото) по скруглённым углам карточки
          margin: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPressStart: (details) {
              _showDeleteButton(photo, details.globalPosition);
            },
            child: InkWell(
              // кликабельная область + эффект волны
              onTap: () => _openDetail(photo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Текст выравнивается по левому краю
                children: [
                  Hero(
                    // анимация "перелёта" картинки на следующий экран
                    tag: photo
                        .id, // одинаковый tag на обоих экранах связывает их
                    child: AspectRatio(
                      aspectRatio: 16 / 9, // все превью одинаковой формы
                      child: Image.memory(
                        photo.bytes,
                        fit: BoxFit.cover,
                        cacheWidth: 800, // декодировать уменьшенную копию: экономит память в списке
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      photo.description.isEmpty
                          ? 'Без описания'
                          : photo.description,
                      maxLines: 2,
                      overflow: TextOverflow
                          .ellipsis, // обрезанный текст заканчивается на «…»
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Метод удаления кнопки из overlay
  void _hideDeleteButton() {
    _deleteButtonEntry?.remove();
    _deleteButtonEntry = null;
  }

  // Метод показа кнопки удаления
  void _showDeleteButton(PhotoEntry photo, Offset position) {
    _hideDeleteButton();

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final screenPadding = MediaQuery.paddingOf(context);

    const buttonWidth = 56.0;
    const buttonHeight = 56.0;

    final left = (position.dx - buttonWidth / 2).clamp(
      screenPadding.left + 8.0,
      screenSize.width - screenPadding.right - buttonWidth - 8.0,
    );

    final top = (position.dy - buttonHeight / 2).clamp(
      screenPadding.top + 8.0,
      screenSize.height - screenPadding.bottom - buttonHeight - 8.0,
    );

    final entry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          // Закрытие кнопки по нажатии в свободном месте
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideDeleteButton,
            ),
          ),
          Positioned(
            left: left,
            top: top,
            width: buttonWidth,
            height: buttonHeight,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  _hideDeleteButton();
                  _confirmAndDelete(photo);
                },
                iconSize: 28,
                tooltip: 'Удалить',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color.fromARGB(255, 112, 112, 112),
                  fixedSize: const Size(56, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ),
        ],
      ),
    );

    _deleteButtonEntry = entry;
    overlay.insert(entry);
  }

  // Отображение окна подтьверждения удаления
  Future<void> _confirmAndDelete(PhotoEntry photo) async {
    final confirmed = await confirmDelete(context);

    if (!confirmed || !mounted) return;

    await _deletePhoto(photo);
  }

  // Удаление фотографии и описания из памяти
  Future<void> _deletePhoto(PhotoEntry photo) async {
    try {
      // 1) Удаление файла фотографии из папки приложения
      await _storage.deleteFile(photo);
      if (!mounted) return;

      // 2) Кдаление описание к фотографии
      setState(() {
        _photos.removeWhere((item) => item.id == photo.id);
      });

      // 3) СОхранение обновлённого списка
      await _storage.saveList(_photos);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Не удалось удалить фото: $e')));
    }
  }
}

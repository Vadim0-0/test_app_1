import 'package:flutter/material.dart';

class WeatherSearchField extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final String? error;
  final bool searchMode;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const WeatherSearchField({
    super.key,
    required this.controller,
    required this.loading,
    required this.error,
    required this.searchMode,
    required this.onSubmitted,
    required this.onChanged,
    required this.onClear,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        // Избранное должно успешно загрузиться до начала работы.
        enabled: !loading && error == null,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted, // поиск с клавиатуры
        // реакция на изменение текста
        onChanged: (value) {
          onChanged(value);
        },
        decoration: InputDecoration(
          hintText: 'Поиск города',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Кнопка очистки
              if (searchMode)
                IconButton(
                  tooltip: 'Очистить',
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                ),
              IconButton(
                tooltip: 'Найти',
                icon: const Icon(Icons.arrow_forward),
                onPressed: loading || error != null
                    ? null
                    : () => onSubmitted(controller.text),
              ),
            ],
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

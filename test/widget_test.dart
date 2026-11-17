import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:test_app_1/app/app.dart';

void main() {
  testWidgets('Главное меню содержит пункт Погода', (tester) async {
    // Создаёт приложение в тестовой среде
    await tester.pumpWidget(const MyApp());

    // Заголовок главного экрана.
    expect(find.text('Мои учебные приложения'), findsOneWidget);

    // Наличие пункта меню.
    expect(find.text('Погода'), findsOneWidget);

    // Иконка погоды.
    expect(find.byIcon(Icons.device_thermostat), findsOneWidget);
  });
}

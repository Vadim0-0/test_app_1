import 'package:flutter/material.dart';

import '../models/weather_models.dart';

Future<bool?> showCityActionsSheet(
  BuildContext context,
  WeatherCity city, {
  required bool favorite,
}) async {
  return await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(city.name), subtitle: Text(city.country)),
              ListTile(
                leading: Icon(favorite ? Icons.star_border : Icons.star),
                title: Text(
                  favorite ? 'Убрать из избранного' : 'Добавить в избранное',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop(true);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

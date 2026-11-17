import '../models/conversion.dart';

// Список всех конвертаций
final List<Conversion> conversions = [
  Conversion('km', 'miles', (v) => v * 0.621371),
  Conversion('miles', 'km', (v) => v / 0.621371),
  Conversion('C', 'F', (v) => v * 9 / 5 + 32),
  Conversion('F', 'C', (v) => (v - 32) * 5 / 9),
  Conversion('KG', 'ID', (v) => v * 2.20462),
  Conversion('ID', 'KG', (v) => v / 2.20462),
];

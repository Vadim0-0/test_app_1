// Название единиц и функция перерасчёта
class Conversion {
  final String from;
  final String to;
  final double Function(double) convert;

  const Conversion(this.from, this.to, this.convert);
}

class GraphicPrice {
  final DateTime time;
  final String open;
  final String close;
  String get price => ((double.parse(open) + double.parse(close)) / 2).toStringAsFixed(2);
  GraphicPrice({required this.time, required this.open, required this.close});

}
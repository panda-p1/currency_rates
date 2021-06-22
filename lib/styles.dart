import 'package:flutter/material.dart';

abstract class CurrencyStyles {
  double currencyNameFontSize();
  double currencyPriceFontSize();
  double iconsSize();
  Color currencyNameFontColor();
}
class PortraitStyles implements CurrencyStyles {
  double currencyNameFontSize() => 30;
  double currencyPriceFontSize() => 50;
  double iconsSize() => 40;
  Color currencyNameFontColor() => Colors.grey[600]!;
}

class LandscapeStyles implements CurrencyStyles {
  double currencyNameFontSize() => 45;
  double currencyPriceFontSize() => 70;
  double iconsSize() => 60;
  Color currencyNameFontColor() => Colors.grey[600]!;
}

class RingStyles {
  static double ringSize = 15;
  static double ringStatusTextSize = 8;
  static double ringPercentTextSize = 15;
  static Color backgroundRingColor = Colors.lightBlue[100]!;
  static double ringWidth = 3;
}

class SucceedDatetime {
  static double fontSize = 11;
}

class ConfigStyles {
  static double fontSize = 30;
  static double arrowIconSize = 25;
  static double arrowSplashRadius = 16;
}
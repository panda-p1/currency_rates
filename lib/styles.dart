import 'package:flutter/material.dart';

abstract class CurrencyStyles {
  double? currencyNameFontSize();
  double currencyPriceFontSize();
  Color? currencyNameFontColor();
  double currencyWidgetHeight();
}

class LayoutStyles {
  static double get footerHeight => 50 + footerPadding * 2;
  static double get appbarHeight => 40;
  static double get footerPadding => 8;
}

class PortraitStyles extends CurrencyStyles {
  double currencyNameFontSize() => 30;
  double currencyPriceFontSize() => 50;
  Color currencyNameFontColor() => Colors.grey[600]!;
  double currencyWidgetHeight() => 120;
}

class LandscapeStyles extends CurrencyStyles {
  double currencyNameFontSize() => 45;
  double currencyPriceFontSize() => 70;
  Color currencyNameFontColor() => Colors.grey[600]!;
  double currencyWidgetHeight() => 220;
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

class AddTickerStyles {
  static double fontSize = 30;
  static double buttonSize = 16;
}


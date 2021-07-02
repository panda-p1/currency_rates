import '../constants.dart';
import '../tools.dart';

class Currency {
  final String type;
  final String baseAsset;
  final String quoteAsset;

  Currency({required this.type, required this.baseAsset, required this.quoteAsset});

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      baseAsset: json['baseAsset'],
      quoteAsset: json['quoteAsset'],
      type: json['baseAsset'] + '-' + json['quoteAsset'],
    );
  }
  toJson() => {
    'type': type,
    'baseAsset': baseAsset,
    'quoteAsset': quoteAsset
  };
}

class BinanceRestCurrencies {
  final List<Currency> currencies;
  final double delay;
  final String time;

  BinanceRestCurrencies({
    required this.currencies,
    required this.delay, required this.time
  });

  // List<dynamic> get arrayOfCurrencies => ['crypto reserved place', eur, eurusd, usd];
  List<dynamic> get arrayOfCurrencies => ['crypto reserved place'];

  factory BinanceRestCurrencies.fromJson(Map<String, dynamic> json) {
    return BinanceRestCurrencies(
        currencies: (json['symbols'] as List).map((e) => Currency.fromJson(e)).toList(),
        delay: json['delay'], time: json['time']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currencies': currencies.map((e) => e.toJson()).toList(),
      'delay': delay,
      'time': time
    };
  }

  Map<Currency_Type, num> getCurrenciesAndTheirRates() {
    Map<Currency_Type, num> obj = {};
    arrayOfCurrencies.skip(1).forEach((element) {
      obj[element.type] = element.price;
    });
    return obj;
  }
}
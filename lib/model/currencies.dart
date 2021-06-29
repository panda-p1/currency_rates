import '../constants.dart';
import '../tools.dart';









class Currency {
  final num price;
  final Grad_Direction gradDirection;
  final Currency_Type type;
  Currency({required this.price, required this.gradDirection, required this.type});

  Map<String, dynamic> toJson() => {
    '${getValueAfterDot(type)}Change': gradDirection.toString().substring(gradDirection.toString().indexOf('.') + 1),
    '${getValueAfterDot(type)}': price
  };
}

class Currencies {
  // final Currency eur;
  // final Currency eurusd;
  // final Currency usd;
  final double delay;
  final String time;

  Currencies({
  //   required this.eur,
  //   required this.eurusd, required this.usd,
    required this.delay, required this.time
  });

  // List<dynamic> get arrayOfCurrencies => ['crypto reserved place', eur, eurusd, usd];
  List<dynamic> get arrayOfCurrencies => ['crypto reserved place'];

  factory Currencies.fromJson(json) {
    return Currencies(
        // eur: Currency(price: double.parse(json['eur'].toString()), gradDirection: stringGradDirToEnum(json['eurChange']), type: stringCurTypeToEnum('eur')),
        // eurusd: Currency(price:double.parse(json['eurusd'].toString()) , gradDirection: stringGradDirToEnum(json['eurusdChange']), type: stringCurTypeToEnum('eurusd')),
        // usd: Currency(price: double.parse(json['usd'].toString()), gradDirection: stringGradDirToEnum(json['usdChange']), type: stringCurTypeToEnum('usd')),
        delay: json['delay'], time: json['time']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // ...eur.toJson(),
      // ...eurusd.toJson(),
      // ...usd.toJson(),
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
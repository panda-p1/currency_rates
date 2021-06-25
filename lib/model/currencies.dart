
import 'package:currencies_pages/api/services.dart';

enum Grad_Direction {
  up,
  down
}



String enumToString(Grad_Direction dir) {
  if(dir == Grad_Direction.down) {
    return 'down';
  }
  if(dir == Grad_Direction.up) {
    return 'up';
  }
  throw Exception();
}

Grad_Direction stringGradDirToEnum(String str) {
  try {
    return Grad_Direction.values.firstWhere(
          (value) => value.toString().split('.')[1] == str,
    );
  } catch (e) {
    print("wrong enum type!!");
    return Grad_Direction.values.first;
  }
}

Theme_Types stringThemeToEnum(String str) {
  try {
    return Theme_Types.values.firstWhere(
          (value) => value.toString().split('.')[1] == str,
    );
  } catch (e) {
    print("wrong enum type!!");
    return Theme_Types.values.first;
  }
}

Currency_Type stringCurTypeToEnum(String str) {
  try {
    return Currency_Type.values.firstWhere(
          (value) => value.toString().split('.')[1] == str,
    );
  } catch (e) {
    print("wrong enum type!!");
    return Currency_Type.values.first;
  }
}
enum Currency_Type {
  brent,
  eur,
  eurusd,
  usd,
  eth,
  doge
}

class Currency {
  final num price;
  final Grad_Direction gradDirection;
  final Currency_Type type;
  Currency({required this.price, required this.gradDirection, required this.type});

  Map<String, dynamic> toJson() => {
    '${type.toString().substring(type.toString().indexOf('.') + 1)}Change': gradDirection.toString().substring(gradDirection.toString().indexOf('.') + 1),
    '${type.toString().substring(type.toString().indexOf('.') + 1)}': price
  };
}

class Currencies {
  final Currency brent;
  final Currency eur;
  final Currency eurusd;
  final Currency usd;
  final double delay;
  final String time;

  Currencies({
    required this.brent, required this.eur,
    required this.eurusd, required this.usd,
    required this.delay, required this.time
  });

  List<Currency> get arrayOfCurrencies => [brent, eur, eurusd, usd];

  factory Currencies.fromJson(json) {
    return Currencies(
        brent: Currency(price: double.parse(json['brent'].toString()), gradDirection: stringGradDirToEnum(json['brentChange']), type: stringCurTypeToEnum('brent')),
        eur: Currency(price: double.parse(json['eur'].toString()), gradDirection: stringGradDirToEnum(json['eurChange']), type: stringCurTypeToEnum('eur')),
        eurusd: Currency(price:double.parse(json['eurusd'].toString()) , gradDirection: stringGradDirToEnum(json['eurusdChange']), type: stringCurTypeToEnum('eurusd')),
        usd: Currency(price: double.parse(json['usd'].toString()), gradDirection: stringGradDirToEnum(json['usdChange']), type: stringCurTypeToEnum('usd')),
        delay: json['delay'], time: json['time']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...brent.toJson(),
      ...eur.toJson(),
      ...eurusd.toJson(),
      ...usd.toJson(),
      'delay': delay,
      'time': time
    };
  }

  Map<Currency_Type, num> getCurrenciesAndTheirRates() {
    Map<Currency_Type, num> obj = {};
    arrayOfCurrencies.forEach((element) {
      obj[element.type] = element.price;
    });
    return obj;
  }
}
import 'dart:math';

import 'constants.dart';
import 'package:currencies_pages/model/crypto.dart';

class CryptoFromBackendHelper {
  static Map<Currency_Pairs, String> _nameByCurrencyType = {
    Currency_Pairs.btcusd: 'BTC-USD',
    Currency_Pairs.ethusd: 'ETH-USD',
    Currency_Pairs.dogeusd: 'DOGE-USD',
    Currency_Pairs.btcrub: 'BTC-RUB',
    Currency_Pairs.btceur: 'BTC-EUR',
    Currency_Pairs.usdrub: 'USD-RUB',
    Currency_Pairs.eurusd: 'EUR-USD',
    Currency_Pairs.eurrub: 'EUR-RUB',
  };
  static Currency_Pairs _getCurrencyType(Map<String, dynamic> crypto) {
    var stringType = crypto['s'].toLowerCase();

    if(stringType.endsWith('t')) {
      List<String> c = stringType.split("");
      c.removeLast();
      stringType = c.join();
    }
    return stringCurPairsToEnum(stringType);
  }
  static String _getPrice(Map<String, dynamic> crypto) {
    var price = ((double.parse(crypto['b'].toString()) + double.parse(crypto['a'].toString())) / 2);
    return makeShortPrice(price);
  }
  static String getNameByCurrencyType(Currency_Pairs type) {
    return _nameByCurrencyType[type]!;
  }
  static String _getName(Map<String, dynamic> crypto) {
    return getNameByCurrencyType(_getCurrencyType(crypto));
  }
  static Currency_Pairs getCurrencyTypeByName(String name) {
    return _nameByCurrencyType.keys.firstWhere((element) => _nameByCurrencyType[element] == name);
  }
  static Crypto createCrypto(Map<String, dynamic> crypto) {
    var price = _getPrice(crypto);
    var type = _getCurrencyType(crypto);
    var name = _getName(crypto);
    return Crypto(name: name, price: price, type: type);
  }
}

double degToRad(double deg) => deg * (pi / 180.0);

String getValueAfterDot(el) {
  return el.toString().substring(el.toString().indexOf('.') + 1);
}

String makeShortPrice(double price) {
  var stringPrice = price.toString();
  return stringPrice = stringPrice.length > 9 ? stringPrice.substring(0, 9) : stringPrice;
}

Grad_Direction stringGradDirToEnum(String str) {
  try {
    return Grad_Direction.values.firstWhere(
          (value) => value.toString().split('.')[1] == str,
    );
  } catch (e) {
    print("wrong enum stringGradDirToEnum type!!");
    return Grad_Direction.values.first;
  }
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

Theme_Types stringThemeToEnum(String str) {
  try {
    return Theme_Types.values.firstWhere(
          (value) => value.toString().split('.')[1] == str,
    );
  } catch (e) {
    print("wrong enum stringThemeToEnum type!!");
    return Theme_Types.values.first;
  }
}
Currency_Pairs stringCurPairsToEnum(String str) {
  try {
    return Currency_Pairs.values.firstWhere(
          (value) => value.toString().split('.')[1] == str,
    );
  } catch (e) {
    print("wrong enum stringCurPairsToEnum type!!");
    return Currency_Pairs.values.first;
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
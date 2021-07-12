import 'dart:math';

import 'constants.dart';
import 'package:currencies_pages/model/crypto.dart';

import 'dart:convert';
import 'dart:math';

class Utils {
  static bool _cached = false;
  static setCached() {
    _cached = true;
  }
  static bool isCached() {
    return _cached;
  }
  static double degToRad(double deg) => deg * (pi / 180.0);

  static String getValueAfterDot(el) {
    return el.toString().substring(el.toString().indexOf('.') + 1);
  }

  static String makeShortPrice(double price) {
    var stringPrice = price.toString();
    while(stringPrice.length < 9) {
      stringPrice+='0';
    }
    return stringPrice = stringPrice.length > 9 ? stringPrice.substring(0, 9) : stringPrice;
  }

  static Theme_Types stringThemeToEnum(String str) {
    try {
      return Theme_Types.values.firstWhere(
            (value) => value.toString().split('.')[1] == str,
      );
    } catch (e) {
      print("wrong enum stringThemeToEnum type!!");
      return Theme_Types.values.first;
    }
  }
  static Currency_Pairs stringCurPairsToEnum(String str) {
    try {
      return Currency_Pairs.values.firstWhere(
            (value) => value.toString().split('.')[1] == str,
      );
    } catch (e) {
      print("wrong enum stringCurPairsToEnum type!!");
      return Currency_Pairs.values.first;
    }
  }
}

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
    return Utils.stringCurPairsToEnum(stringType);
  }
  static String _getPrice(Map<String, dynamic> crypto) {
    var price = ((double.parse(crypto['b'].toString()) + double.parse(crypto['a'].toString())) / 2);
    return Utils.makeShortPrice(price);
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
    var queryName = crypto['s'];
    return Crypto(name: name, price: price, type: type, queryName: queryName);
  }
}


import 'package:currencies_pages/model/currencies.dart';
import 'package:currencies_pages/model/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../constants.dart';
import '../tools.dart';


final darkTheme = ThemeData(
  primarySwatch: Colors.grey,
  primaryColor: Colors.black,
  brightness: Brightness.dark,
  backgroundColor: const Color(0xFF212121),
  accentColor: Colors.white,
  accentIconTheme: IconThemeData(color: Colors.black),
  dividerColor: Color.fromRGBO(48, 48, 48, 1),
);

final lightTheme = ThemeData(
  primarySwatch: Colors.grey,
  primaryColor: Colors.white,
  brightness: Brightness.light,
  backgroundColor: const Color(0xFFE5E5E5),
  accentColor: Colors.black,
  accentIconTheme: IconThemeData(color: Colors.white),
  dividerColor: Color.fromRGBO(250, 250, 250, 1),
);



abstract class LocalDataRepo {
  Future<ThemeData> changeTheme();
  Future<ThemeData> getTheme();
  Future<double> changeDelay(String dir);
  Future<double> getDelay();
  Future<Currencies> getLocalCurrencies();
  Future<Null> storeCurrencies(Currencies currencies);
  Future<Null> storeCrypto(Crypto crypto);
  Future<List<Crypto>> getLocalCrypto();
  Future<Null> removePair(Currency_Pairs pair);
  Future<List<Currency_Pairs>> getChosenPairs();
  Future<Null> saveDefaultPairs();
}

class LocalDataProvider implements LocalDataRepo {

  @override
  Future<Null> removePair(Currency_Pairs pair) async {
    final prefs = await SharedPreferences.getInstance();
    final pairs = jsonDecode(prefs.getString('chosenPairs')!) as List;
    pairs.removeWhere((element) => element == pair);
    prefs.setString('chosenPairs', jsonEncode(pairs.map((e) => getValueAfterDot(e)).toList()));
  }

  @override
  Future<Null> saveDefaultPairs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('chosenPairs', jsonEncode(Currency_Pairs.values.map((e) => getValueAfterDot(e)).toList()));
    return null;
  }
  @override

  @override
  Future<List<Currency_Pairs>> getChosenPairs() async {
    final prefs = await SharedPreferences.getInstance();
    final pairsString = prefs.getString('chosenPairs');
    // if(pairsString == null) {
      saveDefaultPairs();

      return Currency_Pairs.values
          .where((element) => Default_Currency_Pairs.values.map((e) => getValueAfterDot(e)).toList()
          .contains(getValueAfterDot(element))).toList();
    // }

    // final pairsJson = jsonDecode(pairsString) as List;
    // return pairsJson.map((e) => stringCurPairsToEnum(e)).toList();
  }

  @override
  Future<List<Crypto>> getLocalCrypto() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonCrypto = jsonDecode(prefs.getString('crypto')!) as List;
    final cryptoList = jsonCrypto.map((e) => Crypto.fromJson(e)).toList();
    return cryptoList;
  }

  @override
  Future<Null> storeCrypto(Crypto crypto) async {
    final prefs = await SharedPreferences.getInstance();
    // prefs.setString('crypto', jsonEncode([]));
    // prefs.setString('crypto', jsonEncode([]));
    if(prefs.getString('crypto') == null) {
      prefs.setString('crypto', jsonEncode([crypto]));
    }
    final jsonCrypto = jsonDecode(prefs.getString('crypto')!) as List;
    final cryptoList = jsonCrypto.map((e) => Crypto.fromJson(e)).toList();
    if(cryptoList.where((element) => element.name == crypto.name).length == 0) {
      cryptoList.add(crypto);
    } else {
      for(var i = 0; i < cryptoList.length; i++) {
        if(cryptoList[i].name == crypto.name) {
          cryptoList.removeAt(i);
          cryptoList.insert(i, crypto);
          break;
        }
      }
    }
    prefs.setString('crypto', jsonEncode(cryptoList));


    return null;
  }
  @override
  Future<Null> storeCurrencies(Currencies currencies) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('currencies', jsonEncode(currencies.toJson()));
    return null;
  }
  Future<Currencies> getLocalCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonCurrencies = prefs.getString('currencies');
    return Currencies.fromJson(jsonDecode(jsonCurrencies!));
  }
  @override
  Future<double> changeDelay(String dir) async {
    final prefs = await SharedPreferences.getInstance();
    double delay = 30;
    if(dir == '+') {
      delay = (double.parse(prefs.getString('delay')!) + 1);
      prefs.setString('delay', delay.toString());
      return delay;
    }
    if(dir == '-') {
      delay = (double.parse(prefs.getString('delay')!) - 1);
      prefs.setString('delay', delay.toString());
      return delay;
    }
    return delay;
  }
  @override
  Future<double> getDelay() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final delay = double.parse(prefs.getString('delay')!);
      return delay;
    } catch (e) {
      prefs.setString('delay', '20');
      return 20;
    }
  }
  @override
  Future<ThemeData> changeTheme() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final theme = stringThemeToEnum(prefs.getString('themeMode') == null ? '' : prefs.getString('themeMode')!);
      if(theme == Theme_Types.dark) {
        prefs.setString('themeMode', 'light');
        return lightTheme;
      }
      prefs.setString('themeMode', 'dark');
      return darkTheme;
    } catch (e) {
      print(e);
      throw Exception();
    }
  }
  @override
  Future<ThemeData> getTheme() async {

    final prefs = await SharedPreferences.getInstance();
    try {
      final theme = stringThemeToEnum(prefs.getString('themeMode') == null ? '' : prefs.getString('themeMode')!);
      if(theme == Theme_Types.dark) {
        return darkTheme;
      }
      return lightTheme;
    } catch (e) {
      print(e);
      prefs.setString('themeMode', 'dark');
      return lightTheme;
    }
  }

}
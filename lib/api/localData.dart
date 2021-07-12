import 'package:currencies_pages/api/websocket.dart';
import 'package:currencies_pages/model/crypto.dart';
import 'package:currencies_pages/model/currencies.dart';
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
  dividerColor: Color.fromRGBO(250, 250, 250, 1),

);

final lightTheme = ThemeData(
  primarySwatch: Colors.grey,
  primaryColor: Colors.white,
  brightness: Brightness.light,
  backgroundColor: const Color(0xFFE5E5E5),
  accentColor: Colors.black,
  accentIconTheme: IconThemeData(color: Colors.white),
  dividerColor: Color.fromRGBO(48, 48, 48, 1),

);



abstract class LocalDataRepo {
  Future<ThemeData> changeTheme();
  Future<ThemeData> getTheme();
  Future<double> changeDelay(String dir);
  Future<double> getDelay();
  Future<Map<Currency_Pairs, Crypto?>> getLocalCurrencies();
  Future<Null> storeCurrencies(Map<Currency_Pairs, Crypto?> currencies);
  Future<Null> removePair(Currency_Pairs pair);
  Future<List<Currency_Pairs>> getChosenPairs();
  Future<Null> saveDefaultPairs();
  Future<Null> addPair(Currency_Pairs pair);
  Future<List<Currency_Pairs>> getAvailableToAddPairs();
  Future<Null> reorderPairs(int newIdx, Currency_Pairs pair);
  Future<List<Currency_Pairs>> showConnections(Currency_Pairs pair);
  Future<Null> storeBinanceRestapiCurrencies(BinanceRestCurrencies currencies);
  Future<BinanceRestCurrencies> getBinanceRestapiCurrencies();
}

class LocalDataProvider implements LocalDataRepo {
    Future<BinanceRestCurrencies> getBinanceRestapiCurrencies() async {
      final prefs = await SharedPreferences.getInstance();
      final currencies = BinanceRestCurrencies.fromJson(jsonDecode(prefs.getString('binanceCurrencies')!));
      print('LocalDataProvider BinanceRestCurrencies currencies:');
      print(currencies);
      return currencies;
    }
    Future<Null> storeBinanceRestapiCurrencies(BinanceRestCurrencies currencies) async {
      final prefs = await SharedPreferences.getInstance();
      print('LocalDataProvider storeBinanceRestapiCurrencies jsonEncode(currencies):');
      print(jsonEncode(currencies));
      prefs.setString('binanceCurrencies', jsonEncode(currencies));
    }
    Future<Null> reorderPairs(int newIdx, Currency_Pairs pair) async {
    final prefs = await SharedPreferences.getInstance();
    final pairsJson = jsonDecode(prefs.getString('chosenPairs')!) as List;
    final pairString = Utils.getValueAfterDot(pair);
    final oldIdx = pairsJson.indexOf(pairString);
    pairsJson.removeAt(oldIdx);
    pairsJson.insert(newIdx, pairString);
    prefs.setString('chosenPairs', jsonEncode(pairsJson));

    final currencies = await getLocalCurrencies();
    final List<MapEntry<Currency_Pairs, Crypto?>> list = [];
    currencies.forEach((k,v) => list.add(MapEntry(k,v)));
    final oldIndex = currencies.keys.toList().indexOf(pair);
    list.removeAt(oldIndex);
    list.insert(newIdx, MapEntry(pair, currencies[pair]));
    final Map<Currency_Pairs, Crypto?> newCurrencies = {};
    newCurrencies.addEntries(list);
    await storeCurrencies(newCurrencies);
  }
  Future<List<Currency_Pairs>> getAvailableToAddPairs() async {
    final prefs = await SharedPreferences.getInstance();
    final pairsJson = jsonDecode(prefs.getString('chosenPairs')!) as List;
    final pairs = pairsJson.map((e) => Utils.stringCurPairsToEnum(e)).toList();
    return Currency_Pairs.values.where((element) => !pairs.contains(element)).toList();
  }
  @override
  Future<Null> addPair(Currency_Pairs pair) async {
    final prefs = await SharedPreferences.getInstance();
    final pairsJson = jsonDecode(prefs.getString('chosenPairs')!) as List;
    final pairString = Utils.getValueAfterDot(pair);
    pairsJson.insert(0, pairString);
    prefs.setString('chosenPairs', jsonEncode(pairsJson));
  }
  @override
  Future<List<Currency_Pairs>> showConnections(Currency_Pairs pair) async {
    final pairs = await getChosenPairs();
    return currencyChains[pair]!.where((element) => pairs.contains(element)).toList();
  }
  @override
  Future<Null> removePair(Currency_Pairs pair) async {
    final prefs = await SharedPreferences.getInstance();
    final pairs = await getChosenPairs();
    final localCurrencies = await getLocalCurrencies();

    pairs.removeWhere((element) => element == pair);
    prefs.setString('chosenPairs', jsonEncode(pairs.map((e) => Utils.getValueAfterDot(e)).toList()));

    localCurrencies.remove(pair);
    await storeCurrencies(localCurrencies);
  }

  @override
  Future<Null> saveDefaultPairs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('chosenPairs', jsonEncode(Currency_Pairs.values.map((e) => Utils.getValueAfterDot(e)).toList()));
    return null;
  }
  @override

  @override
  Future<List<Currency_Pairs>> getChosenPairs() async {
    final prefs = await SharedPreferences.getInstance();
    final pairsString = prefs.getString('chosenPairs');
    if(pairsString == null) {
      saveDefaultPairs();
      return Currency_Pairs.values
          .where((element) => Default_Currency_Pairs.values.map((e) => Utils.getValueAfterDot(e)).toList()
          .contains(Utils.getValueAfterDot(element))).toList();
    }
    final pairsJson = jsonDecode(pairsString) as List;
    return pairsJson.map((e) => Utils.stringCurPairsToEnum(e)).toList();
  }

  @override
  Future<Null> storeCurrencies(Map<Currency_Pairs, Crypto?> currencies) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('currencies', jsonEncode(
      currencies.map((key, crypto) =>
        MapEntry(Utils.getValueAfterDot(key), crypto != null ? crypto.toJson() : null)
      )
    ));
    return null;
  }
  Future<Map<Currency_Pairs, Crypto?>> getLocalCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonCurrencies = jsonDecode(prefs.getString('currencies')!) as Map;
    return jsonCurrencies.map((pair, crypto) =>
        MapEntry(Utils.stringCurPairsToEnum(pair), crypto != null ? Crypto.fromJson(crypto) : null)
    );
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
      prefs.setString('delay', '$DEFAULT_DELAY');
      return DEFAULT_DELAY;
    }
  }
  @override
  Future<ThemeData> changeTheme() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final theme = Utils.stringThemeToEnum(prefs.getString('themeMode') == null ? '' : prefs.getString('themeMode')!);
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
      final theme = Utils.stringThemeToEnum(prefs.getString('themeMode') == null ? '' : prefs.getString('themeMode')!);
      if(theme == Theme_Types.dark) {
        return darkTheme;
      }
      return lightTheme;
    } catch (e) {
      print(e);
      prefs.setString('themeMode', 'dark');
      return darkTheme;
    }
  }

}
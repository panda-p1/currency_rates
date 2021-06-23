import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:async' show Future;
import 'package:currencies_pages/model/currencies.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

enum Theme_Types {
  light,
  dark
}
abstract class CurrencyRepo {
  Future<Currencies> getRates(double timeout);
}

class CurrencyProvider implements CurrencyRepo {
  @override
  Future<Currencies> getRates(double timeout) async {
    final response = await http.get(Uri.parse('http://kursorub.com/rest/data?cis=8&v=40&sa=0&t=162392525514'))
    .timeout(Duration(milliseconds: (timeout * 1000).toInt()));
      // http.get(Uri.parse('http://kursorub.com/rest/data?cis=8&v=40&sa=0&t=162392525514'))
    final delay = await LocalDataProvider().getDelay();
    return Currencies.fromJson({...jsonDecode(response.body) as Map, ...{"delay": delay}, ...{"time": DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now())}});
  }
}

abstract class LocalDataRepo {
  Future<ThemeData> changeTheme();
  Future<ThemeData> getTheme();
  Future<double> changeDelay(String dir);
  Future<double> getDelay();
  Future<Null> storeCurrencies(Currencies currencies);
  Future<Currencies> getLocalCurrencies();
}

class LocalDataProvider implements LocalDataRepo {
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
      prefs.setString('themeMode', 'light');
      return lightTheme;
    }
  }

}
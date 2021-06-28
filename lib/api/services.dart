import 'dart:convert';
import 'package:currencies_pages/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:async' show Future, StreamController;
import 'package:currencies_pages/model/currencies.dart';
import 'package:currencies_pages/model/crypto.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';

enum Crypto_Type {
  btc,
  eth,
  doge
}

const btcUsdUrl = 'wss://stream.binance.com:9443/stream?streams=btcusdt@bookTicker';
const ethUrl = 'wss://stream.binance.com:9443/stream?streams=ethusdt@bookTicker';
const dogeUrl = 'wss://stream.binance.com:9443/stream?streams=dogeusdt@bookTicker';
const btcRubUrl = 'wss://stream.binance.com:9443/stream?streams=btcrub@bookTicker';
const btcEurUrl = 'wss://stream.binance.com:9443/stream?streams=btceur@bookTicker';

List<String> urls = [btcUsdUrl,ethUrl,dogeUrl,btcRubUrl,btcEurUrl];

Map<Currency_Pairs,List<Currency_Pairs>> currencyChains = {
  Currency_Pairs.btcusd: [Currency_Pairs.btcusd, Currency_Pairs.usdrub, Currency_Pairs.eurusd],
  Currency_Pairs.btceur: [Currency_Pairs.btceur, Currency_Pairs.eurrub, Currency_Pairs.eurusd],
  Currency_Pairs.btcrub: [Currency_Pairs.btcrub, Currency_Pairs.eurrub, Currency_Pairs.usdrub],
  Currency_Pairs.eurusd: [Currency_Pairs.eurusd],
  Currency_Pairs.eurrub: [Currency_Pairs.eurrub],
  Currency_Pairs.usdrub: [Currency_Pairs.usdrub],
  Currency_Pairs.dogeusd: [Currency_Pairs.dogeusd],
  Currency_Pairs.ethusd: [Currency_Pairs.ethusd],
};

Map<Currency_Pairs, String> pairsUrls = {
  Currency_Pairs.btcusd: btcUsdUrl,
  Currency_Pairs.btceur: btcEurUrl,
  Currency_Pairs.btcrub: btcRubUrl,
  Currency_Pairs.dogeusd: dogeUrl,
  Currency_Pairs.ethusd: ethUrl,
};

class NotificationController {

  static NotificationController? _singleton;

  List<StreamController> streamControllers = urls.map((e) => StreamController.broadcast(sync: true)).toList();

  List<Map<Currency_Pairs, WebSocket>> channels = [];

  List<Currency_Pairs> closeConnection(Currency_Pairs pair) {
    return currencyChains[pair]!;
  }

  static NotificationController getInstance() {
    if(_singleton == null) {
      _singleton = NotificationController();
    }
    return _singleton!;
  }
  closeAllConnections() {
    for(var i = 0; i < channels.length; i ++) {
      channels[i].entries.toList()[0].value.close();
    }
  }
  initWebSocketConnection() async {
    print("conecting...");
    channels = (await connectWs()).asMap().entries.map((e) {
      print(e);
      return {Currency_Pairs.values[e.key]: e.value};
    }).toList();
    print("socket connection initializied");
    // channels.forEach((element) {
    //   element!.done.then((dynamic _) => _onDisconnected());
    // });
    broadcastNotifications();
  }
  broadcastNotifications() {
    for(var i = 0; i < channels.length; i ++) {
      channels[i].values.toList()[0].listen((streamData) {
        streamControllers[i].add(streamData);
      });
    }
  }
  Future<List<WebSocket>> connectWs() async {
    return await Future.wait(pairsUrls.entries.map((e) => WebSocket.connect(e.value)).toList());
  }
  void _onDisconnected() {
    // initWebSocketConnection();
  }
}

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
    final delay = await LocalDataProvider().getDelay();
    return Currencies.fromJson({...jsonDecode(response.body) as Map, ...{"delay": delay}, ...{"time": DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now())}});
  }
}

abstract class LocalDataRepo {
  Future<ThemeData> changeTheme();
  Future<ThemeData> getTheme();
  Future<double> changeDelay(String dir);
  Future<double> getDelay();
  Future<Currencies> getLocalCurrencies();
  Future<Null> storeCurrencies(Currencies currencies);
  Future<Null> storeCrypto(Crypto crypto);
  Future<List<Crypto>> getLocalCrypto();
}

class LocalDataProvider implements LocalDataRepo {
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
      prefs.setString('themeMode', 'light');
      return lightTheme;
    }
  }

}
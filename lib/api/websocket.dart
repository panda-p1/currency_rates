import 'dart:async' show Future, StreamController;
import 'dart:convert';
import 'dart:io';

import 'package:currencies_pages/model/crypto.dart';

import '../constants.dart';
import '../tools.dart';
import 'localData.dart';

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
  var btcrub = '';
  var btceur = '';
  var btcusd = '';
  static NotificationController? _singleton;
  late List<Currency_Pairs> pairs;
  StreamController<Map<Currency_Pairs, Crypto?>> streamController = StreamController.broadcast(sync: true);
  late Map<Currency_Pairs, Crypto?> obj;

  Map<Currency_Pairs, WebSocket> channels = {};

  List<Currency_Pairs> closeConnection(Currency_Pairs pair) {
    return currencyChains[pair]!;
  }

  confirmedCloseConnection(List<Currency_Pairs> pairss) {
    pairs.removeWhere((element) => pairss.contains(element));

    pairss.forEach((element) {
      LocalDataProvider().removePair(element);

      if(channels.containsKey(element)) {
        channels[element]!.close();
        channels.remove(element);
      }
      obj.remove(element);
    });
    print('confirmedCloseConnection');
  }

  static NotificationController getInstance() {
    if(_singleton == null) {
      _singleton = NotificationController();
    }
    return _singleton!;
  }

  closeAllConnections() {
    for(var i = 0; i < channels.length; i++) {
      print(i);
      channels.values.toList()[i].close();
    }
  }

  addListener(Currency_Pairs pair) {
    if(!pairsUrls.containsKey(pair)) {
      throw Exception('pairsUrls does not contain this pair');
    }

    if(pair == Currency_Pairs.dogeusd) {
      channels[Currency_Pairs.dogeusd]!.listen((streamData) {
        final crypto = CryptoFromBackendHelper.createCrypto(jsonDecode(streamData)['data']);
        obj[crypto.type] = crypto;
        streamController.add(obj);
      });
      return;
    }
    if(pair == Currency_Pairs.ethusd) {
      channels[Currency_Pairs.ethusd]!.listen((streamData) {
        final crypto = CryptoFromBackendHelper.createCrypto(jsonDecode(streamData)['data']);
        obj[crypto.type] = crypto;
        streamController.add(obj);
      });
      return;
    }
    print(pairs);
    channels[pair]!.listen((streamData) {
      final crypto = CryptoFromBackendHelper.createCrypto(jsonDecode(streamData)['data']);
      if(crypto.type == Currency_Pairs.btcusd) btcusd = crypto.price;
      if(crypto.type == Currency_Pairs.btceur) btceur = crypto.price;
      if(crypto.type == Currency_Pairs.btcrub) btcrub = crypto.price;
      obj[crypto.type] = crypto;

      if(pairs.contains(Currency_Pairs.eurrub) &&
          btcrub.isNotEmpty && btceur.isNotEmpty
          && (crypto.type == Currency_Pairs.btcrub || crypto.type == Currency_Pairs.btceur)) {
        obj[Currency_Pairs.eurrub] = Crypto(
            name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.eurrub),
            price: makeShortPrice(double.parse(btcrub) / double.parse(btceur)),
            type: Currency_Pairs.eurrub);
      }
      if(pairs.contains(Currency_Pairs.eurusd) &&
          btceur.isNotEmpty && btcusd.isNotEmpty
          && (crypto.type == Currency_Pairs.btceur || crypto.type == Currency_Pairs.btcusd)) {
        obj[Currency_Pairs.eurusd] = Crypto(
            name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.eurusd),
            price: makeShortPrice(double.parse(btcusd) / double.parse(btceur)),
            type: Currency_Pairs.eurusd);
      }
      if(pairs.contains(Currency_Pairs.usdrub) &&
          btcusd.isNotEmpty && btcrub.isNotEmpty
          && (crypto.type == Currency_Pairs.btcusd || crypto.type == Currency_Pairs.btcrub)) {
        obj[Currency_Pairs.usdrub] =  Crypto(
            name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.usdrub),
            price: makeShortPrice(double.parse(btcrub) / double.parse(btcusd)),
            type: Currency_Pairs.usdrub);
      }
      streamController.add(obj);
      return;
    });

  }

  initWebSocketConnection() async {
    print("connecting...");
    pairs = await LocalDataProvider().getChosenPairs();
    print(pairs);
    obj = {for (var pair in pairs) pair: null};
    final websockets = await Future.wait(
        pairsUrls.keys.where((element) => pairs.contains(element)).toList()
            .map((e) => connectWs(MapEntry(e, pairsUrls[e]!))).toList());
    channels = {for (var v in websockets) pairs[websockets.indexOf(v)]: v };
    print(channels.keys);
    for(var channel in channels.keys) {
      addListener(channel);
    }

    print("socket connection initializied");
    channels.forEach((key, value) {
      value.done.then((dynamic _) => _onDisconnected());
    });
    // channels.forEach((element) {
    //   // element!.done.then((dynamic _) => _onDisconnected());
    // });
    // broadcastNotifications();
  }

  broadcastNotifications() {
    var btcrub = '';
    var btceur = '';
    var btcusd = '';
    for(var key in channels.keys) {
      channels[key]!.listen((streamData) {
        final crypto = CryptoFromBackendHelper.createCrypto(jsonDecode(streamData)['data']);
        
        if(crypto.type == Currency_Pairs.btcusd) btcusd = crypto.price;
        if(crypto.type == Currency_Pairs.btceur) btceur = crypto.price;
        if(crypto.type == Currency_Pairs.btcrub) btcrub = crypto.price;
        obj[crypto.type] = crypto;
        print(obj);

        if( pairs.contains(Currency_Pairs.eurrub) &&
            btcrub.isNotEmpty && btceur.isNotEmpty 
            && (crypto.type == Currency_Pairs.btcrub || crypto.type == Currency_Pairs.btceur)) {
              obj[Currency_Pairs.eurrub] = Crypto(
                  name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.eurrub),
                  price: makeShortPrice(double.parse(btcrub) / double.parse(btceur)),
                  type: Currency_Pairs.eurrub);
        }
        if( pairs.contains(Currency_Pairs.eurusd) &&
            btceur.isNotEmpty && btcusd.isNotEmpty
            && (crypto.type == Currency_Pairs.btceur || crypto.type == Currency_Pairs.btcusd)) {
              obj[Currency_Pairs.eurusd] = Crypto(
                  name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.eurusd),
                  price: makeShortPrice(double.parse(btcusd) / double.parse(btceur)),
                  type: Currency_Pairs.eurusd);
        }
        if( pairs.contains(Currency_Pairs.usdrub) &&
            btcusd.isNotEmpty && btcrub.isNotEmpty
            && (crypto.type == Currency_Pairs.btcusd || crypto.type == Currency_Pairs.btcrub)) {
              obj[Currency_Pairs.usdrub] =  Crypto(
                  name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.usdrub),
                  price: makeShortPrice(double.parse(btcrub) / double.parse(btcusd)),
                  type: Currency_Pairs.usdrub);
        }
        streamController.add(obj);

      });
    }
  }

  Future<WebSocket> connectWs(MapEntry<Currency_Pairs, String> pair) async {
    return await WebSocket.connect(pair.value);
  }
  void _onDisconnected() {
    // initWebSocketConnection();
  }
}


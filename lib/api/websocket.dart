import 'dart:async' show Future, StreamController;
import 'dart:convert';
import 'dart:io';

import 'package:currencies_pages/model/crypto.dart';

import '../constants.dart';
import '../tools.dart';
import 'localData.dart';

const BTCUSDURL = 'wss://stream.binance.com:9443/stream?streams=btcusdt@bookTicker';
const ETHUSDURL = 'wss://stream.binance.com:9443/stream?streams=ethusdt@bookTicker';
const DOGEUSDURL = 'wss://stream.binance.com:9443/stream?streams=dogeusdt@bookTicker';
const BTCRUBURL = 'wss://stream.binance.com:9443/stream?streams=btcrub@bookTicker';
const BTCEURURL = 'wss://stream.binance.com:9443/stream?streams=btceur@bookTicker';

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

Map<Currency_Pairs,List<Currency_Pairs>> reversedCurrencyChain = {
  Currency_Pairs.btcusd: [Currency_Pairs.btcusd],
  Currency_Pairs.btceur: [Currency_Pairs.btceur],
  Currency_Pairs.btcrub: [Currency_Pairs.btcrub],
  Currency_Pairs.eurusd: [Currency_Pairs.btcusd, Currency_Pairs.btceur],
  Currency_Pairs.eurrub: [Currency_Pairs.btceur, Currency_Pairs.btcrub],
  Currency_Pairs.usdrub: [Currency_Pairs.btcusd, Currency_Pairs.btcrub],
  Currency_Pairs.dogeusd: [Currency_Pairs.dogeusd],
  Currency_Pairs.ethusd: [Currency_Pairs.ethusd],
};

Map<Currency_Pairs, String> pairsUrls = {
  Currency_Pairs.btcusd: BTCUSDURL,
  Currency_Pairs.btceur: BTCEURURL,
  Currency_Pairs.btcrub: BTCRUBURL,
  Currency_Pairs.dogeusd: DOGEUSDURL,
  Currency_Pairs.ethusd: ETHUSDURL,
};

class NotificationController {
  var btcrub = '';
  var btceur = '';
  var btcusd = '';
  static NotificationController? _singleton;

  static NotificationController getInstance() {
    if(_singleton == null) {
      _singleton = NotificationController();
    }
    return _singleton!;
  }

  isEmpty() {
    return obj.isEmpty;
  }

  List<Currency_Pairs> pairs = [];
  StreamController<Map<Currency_Pairs, Crypto?>> streamController = StreamController.broadcast(sync: true);
  late Map<Currency_Pairs, Crypto?> obj;

  Map<Currency_Pairs, WebSocket> channels = {};

  List<Currency_Pairs> closeConnection(Currency_Pairs pair) {
    return currencyChains[pair]!.where((element) => obj.keys.contains(element)).toList();
  }

  reorderPair(int newIdx, Currency_Pairs pair) {
    // @TODO FIX REORDER BUGS
    final Map<Currency_Pairs, Crypto?> newObj = {};
    final oldIndex = obj.keys.toList().indexOf(pair);
    if(newIdx > oldIndex) {
      print(obj);
      for(var key in obj.keys) {
        final keyIdx = obj.keys.toList().indexOf(key);
        if(keyIdx < oldIndex) {
          newObj[key] = obj[key];
        }
        if(keyIdx >= oldIndex && keyIdx < newIdx) {
          newObj[key] = obj[keyIdx + 1];
        }

        if(newIdx == keyIdx) {
          print('=');
          newObj[pair] = obj[pair];
        }

        if(newIdx > keyIdx) {
          print('>');
          newObj[key] = obj[keyIdx];
        }
      }
      print(newObj);
      obj = newObj;
    }

  }

  Future<void> confirmedCloseConnection(List<Currency_Pairs> pairss) async {
    for(var pair in pairss) {
      LocalDataProvider().removePair(pair);
      if(channels.containsKey(pair)) {
        await channels[pair]!.close();
        channels.remove(pair);
      }

      pairs.removeWhere((element) => pairss.contains(element));

      if(!pairsUrls.keys.contains(pair) && !pairss.where((element) => element != pair).any((element) => currencyChains[element]!.contains(pair))) { // REMOVING TICKERS THAT HAS NO URL AND WILL NOT BE DELETED BY ITS CHAINS URL
        obj.remove(pair);
      }
    }
  }

  closeAllConnections() {
    for(var i = 0; i < channels.length; i++) {
      channels.values.toList()[i].close();
    }
  }

  addPair(Currency_Pairs pair) async {
    final requiredToStartListenPairs = reversedCurrencyChain[pair]!;
    pairs.add(pair);
    _addToBeginningOfObj(pair);
    for(var channelName in requiredToStartListenPairs) {
      if(!channels.keys.contains(channelName)) {
        channels.addEntries([MapEntry(channelName, await connectWs(MapEntry(channelName, pairsUrls[channelName]!)))]);
        _addListener(channelName);
      }
    }
  }
  _addToBeginningOfObj(Currency_Pairs pair) {
    obj = {...{pair: null},...obj};
  }
  _addListener(Currency_Pairs pair) {
    if(!pairsUrls.containsKey(pair)) {
      throw Exception('pairsUrls does not contain this pair');
    }

    if(pair == Currency_Pairs.dogeusd || pair == Currency_Pairs.ethusd) {
      channels[pair]!.listen((streamData) {
        final crypto = CryptoFromBackendHelper.createCrypto(jsonDecode(streamData)['data']);
        obj[crypto.type] = crypto;
        streamController.add(obj);
      }).onDone(() {
        for (var chain in currencyChains[pair]!) {
          obj.remove(chain);
        }
      });
      return;
    }

    channels[pair]!.listen((streamData) {
      final crypto = CryptoFromBackendHelper.createCrypto(jsonDecode(streamData)['data']);
      if(crypto.type == Currency_Pairs.btcusd) btcusd = crypto.price;
      if(crypto.type == Currency_Pairs.btceur) btceur = crypto.price;
      if(crypto.type == Currency_Pairs.btcrub) btcrub = crypto.price;

      if(pairs.contains(crypto.type)) {
        obj[crypto.type] = crypto;
      }

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
    }).onDone(() {
      for (var chain in currencyChains[pair]!) {
        obj.remove(chain);
      }
    });
  }

  initWebSocketConnection() async {
    print("connecting...");
    final chosenPairs = await LocalDataProvider().getChosenPairs();
    obj = {for (var pair in chosenPairs) pair: null};
    for(var pair in chosenPairs.reversed) {
      addPair(pair);
    }
  }

  Future<WebSocket> connectWs(MapEntry<Currency_Pairs, String> pair) async {
    return await WebSocket.connect(pair.value);
  }
  void _onDisconnected() {
    // initWebSocketConnection();
  }
}


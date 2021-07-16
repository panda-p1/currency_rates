import 'dart:async' show Future, StreamController;
import 'dart:convert';
import 'dart:io';

import 'package:currencies_pages/bloc/crypto/states.dart';
import 'package:currencies_pages/model/crypto.dart';
import 'package:currencies_pages/model/graphic_price.dart';

import '../constants.dart';
import '../tools.dart';
import 'localData.dart';

const BTCUSDURL = 'wss://stream.binance.com:9443/stream?streams=btcusdt@ticker';
const ETHUSDURL = 'wss://stream.binance.com:9443/stream?streams=ethusdt@ticker';
const DOGEUSDURL = 'wss://stream.binance.com:9443/stream?streams=dogeusdt@ticker';
const BTCRUBURL = 'wss://stream.binance.com:9443/stream?streams=btcrub@ticker';
const BTCEURURL = 'wss://stream.binance.com:9443/stream?streams=btceur@ticker';
//
// Map<Currency_Pairs,List<Currency_Pairs>> currencyChains = {
//   Currency_Pairs.btcusd: [Currency_Pairs.btcusd, Currency_Pairs.usdrub, Currency_Pairs.eurusd],
//   Currency_Pairs.btceur: [Currency_Pairs.btceur, Currency_Pairs.eurrub, Currency_Pairs.eurusd],
//   Currency_Pairs.btcrub: [Currency_Pairs.btcrub, Currency_Pairs.eurrub, Currency_Pairs.usdrub],
//   Currency_Pairs.eurusd: [Currency_Pairs.eurusd],
//   Currency_Pairs.eurrub: [Currency_Pairs.eurrub],
//   Currency_Pairs.usdrub: [Currency_Pairs.usdrub],
//   // Currency_Pairs.dogeusd: [Currency_Pairs.dogeusd],
//   Currency_Pairs.ethusd: [Currency_Pairs.ethusd],
// };
//
// Map<Currency_Pairs,List<Currency_Pairs>> reversedCurrencyChain = {
//   Currency_Pairs.btcusd: [Currency_Pairs.btcusd],
//   Currency_Pairs.btceur: [Currency_Pairs.btceur],
//   Currency_Pairs.btcrub: [Currency_Pairs.btcrub],
//   Currency_Pairs.eurusd: [Currency_Pairs.btcusd, Currency_Pairs.btceur],
//   Currency_Pairs.eurrub: [Currency_Pairs.btceur, Currency_Pairs.btcrub],
//   Currency_Pairs.usdrub: [Currency_Pairs.btcusd, Currency_Pairs.btcrub],
//   // Currency_Pairs.dogeusd: [Currency_Pairs.dogeusd],
//   Currency_Pairs.ethusd: [Currency_Pairs.ethusd],
// };
//
// Map<Currency_Pairs, String> pairsUrls = {
//   Currency_Pairs.btcusd: BTCUSDURL,
//   Currency_Pairs.btceur: BTCEURURL,
//   Currency_Pairs.btcrub: BTCRUBURL,
//   // Currency_Pairs.dogeusd: DOGEUSDURL,
//   Currency_Pairs.ethusd: ETHUSDURL,
// };



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

  String getUrlByPair(String tickerName) {
    return 'wss://stream.binance.com:9443/stream?streams=${tickerName.toLowerCase()}@ticker';
  }
  List<String> pairs = [];
  Map<String, StreamController<Crypto?>> streamControllers = {};

  late Map<String, Crypto?> obj;

  Map<String, WebSocket> channels = {};

  reorderPair(int newIdx, String pair) {
    final List<MapEntry<String, Crypto?>> list = [];
    obj.forEach((k,v) => list.add(MapEntry(k,v)));
    final oldIndex = obj.keys.toList().indexOf(pair);
    list.removeAt(oldIndex);
    list.insert(newIdx, MapEntry(pair, obj[pair]));

    final Map<String, Crypto?> newObj = {};
    newObj.addEntries(list);
    obj = {...newObj};
  }

  Future<void> confirmedCloseConnection(String pair) async {
    if(channels[pair] != null) {
      channels[pair]!.close();
    }
    pairs.remove(pair);
    obj.remove(pair);
  }

  addStreamCtrl(String pair) {
    streamControllers[pair] =  StreamController.broadcast(sync: true);
  }

  closeAllConnections() {
    for(var i = 0; i < channels.length; i++) {
      channels.values.toList()[i].close();
    }
  }

  addPair(String pair) async {
    pairs.add(pair);
    _addToBeginningOfObj(pair);
    addStreamCtrl(pair);
    channels.addEntries([MapEntry(pair, await connectWs(pair))]);
    _addListener(pair);
  }

  _addToBeginningOfObj(String pair) {
    obj = {...{pair: null},...obj};
  }
  _onDoneChannel(String pair) {
    streamControllers[pair]!.addError(ClosedCrypto());

    // if(channels[pair] != null) {
    //   if(channels[pair]!.closeCode == 1002) {
    //     // streamController.addError(CryptoError());
    //   }
    // }
    //
    channels.remove(pair);
    //
    // for (var chain in currencyChains[pair]!) {
    //   obj.remove(chain);
    // }
  }
  _addListener(String pair) {
    print('add listener');
    print('pair');
    print(pair);
    channels[pair]!.listen((streamData) {
      final crypto = CryptoFromBackendHelper.createCrypto(jsonDecode(streamData)['data']);
      obj[crypto.name] = crypto;

      streamControllers[pair]!.add(crypto);

      // if(pairs.contains(Currency_Pairs.eurrub) &&
      //     btcrub.isNotEmpty && btceur.isNotEmpty
      //     && (crypto.type == Currency_Pairs.btcrub || crypto.type == Currency_Pairs.btceur)) {
      //   obj[Currency_Pairs.eurrub] = Crypto(
      //       name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.eurrub),
      //       price: Utils.makeShortPrice(double.parse(btcrub) / double.parse(btceur)),
      //       type: Currency_Pairs.eurrub,
      //   );
      // }
      // if(pairs.contains(Currency_Pairs.eurusd) &&
      //     btceur.isNotEmpty && btcusd.isNotEmpty
      //     && (crypto.type == Currency_Pairs.btceur || crypto.type == Currency_Pairs.btcusd)) {
      //   obj[Currency_Pairs.eurusd] = Crypto(
      //       name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.eurusd),
      //       price: Utils.makeShortPrice(double.parse(btcusd) / double.parse(btceur)),
      //       type: Currency_Pairs.eurusd);
      // }
      // if(pairs.contains(Currency_Pairs.usdrub) &&
      //     btcusd.isNotEmpty && btcrub.isNotEmpty
      //     && (crypto.type == Currency_Pairs.btcusd || crypto.type == Currency_Pairs.btcrub)) {
      //   obj[Currency_Pairs.usdrub] =  Crypto(
      //       name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.usdrub),
      //       price: Utils.makeShortPrice(double.parse(btcrub) / double.parse(btcusd)),
      //       type: Currency_Pairs.usdrub);
      // }
      // streamController.add(obj);
      return;
    }).onDone(() => _onDoneChannel(pair));
  }

  _initPairs(List<String> pairss) async {
    pairs.addAll(pairss);
    pairs.forEach((element) {addStreamCtrl(element);});
    final Map<String, String> channelPairs = {};
    pairss.forEach((e) {
      channelPairs[e] = getUrlByPair(e);
    });
    final websockets = await _initConnectWs(channelPairs);
    print(websockets);
    channels = {for(var i in List.generate(websockets.length, (index) => index)) channelPairs.keys.toList()[i]: websockets[i]};
    channels.forEach((key, value) {
      _addListener(key);
    });
  }
  initWebSocketConnection() async {
    print("connecting...");
    final chosenPairs = await LocalDataProvider().getChosenPairs();
    print(chosenPairs);
    obj = {for (var pair in chosenPairs) pair: null};
    await _initPairs(chosenPairs);
  }
  
  Future<List<WebSocket>> _initConnectWs(Map<String, String> pairs) async {
    return await Future.wait(pairs.values.map((e) => WebSocket.connect(e)));
  }

  Future<WebSocket> connectWs(String pair) async {
    return await WebSocket.connect(getUrlByPair(pair));
  }
  void _onDisconnected() {
    // initWebSocketConnection();
  }
}


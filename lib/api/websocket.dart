import 'dart:async' show Future, StreamController;
import 'dart:convert';
import 'dart:io';

import 'package:currencies_pages/model/crypto.dart';
import '../tools.dart';
import 'localData.dart';

class NotificationController {
  static NotificationController? _singleton;

  static NotificationController getInstance() {
    if(_singleton == null) {
      _singleton = NotificationController();
    }
    return _singleton!;
  }

  String getUrlByPair(String tickerName) {
    return 'wss://stream.binance.com:9443/stream?streams=${tickerName.toLowerCase()}@ticker';
  }
  List<String> pairs = [];
  Map<String, StreamController<Crypto?>> streamControllers = {};

  Map<String, WebSocket> channels = {};

  Map<String, StreamController<Crypto?>> reorderPair(int newIdx, String pair) {
    final List<MapEntry<String, StreamController<Crypto?>>> list = [];
    streamControllers.forEach((k,v) => list.add(MapEntry(k,v)));
    final oldIndex = streamControllers.keys.toList().indexOf(pair);
    final item = list.removeAt(oldIndex);
    list.insert(newIdx, MapEntry(pair, item.value));

    final Map<String, StreamController<Crypto?>> newObj = {};
    newObj.addEntries(list);
    streamControllers = {...newObj};
    return streamControllers;
  }

  Future<void> confirmedCloseConnection(String pair) async {

    if(channels[pair] != null) {
      channels[pair]!.close();
    }
    pairs.remove(pair);
  }

  addStreamCtrl(String pair) {
    streamControllers[pair] = StreamController.broadcast(sync: true);
  }

  closeAllConnections() {
    for(var i = 0; i < channels.length; i++) {
      confirmedCloseConnection(channels.keys.toList()[i]);
    }
    pairs = [];
  }

  addPair(String pair) async {
    pairs.add(pair);
    addStreamCtrl(pair);
    channels.addEntries([MapEntry(pair, await connectWs(pair))]);
    _addListener(pair);
  }

  _onDoneChannel(String pair) {
    channels.remove(pair);
    streamControllers.remove(pair);
  }
  _addListener(String pair) {
    channels[pair]!.listen((streamData) {
      final crypto = CryptoFromBackendHelper.createCrypto(jsonDecode(streamData)['data']);
      if(streamControllers[pair] != null && !streamControllers[pair]!.isClosed) {
        streamControllers[pair]!.add(crypto);
      }

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
    channels = {for(var i in List.generate(websockets.length, (index) => index)) channelPairs.keys.toList()[i]: websockets[i]};
    channels.forEach((key, value) {
      _addListener(key);
    });
  }
  initWebSocketConnection() async {
    print("connecting...");
    final chosenPairs = await LocalDataProvider().getChosenPairs();
    await _initPairs(chosenPairs);
  }

  Future<List<WebSocket>> _initConnectWs(Map<String, String> pairs) async {
    return await Future.wait(pairs.values.map((e) => WebSocket.connect(e)));
  }

  Future<WebSocket> connectWs(String pair) async {
    return await WebSocket.connect(getUrlByPair(pair));
  }
}


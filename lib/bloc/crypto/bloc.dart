import 'dart:async';
import 'package:currencies_pages/api/localData.dart';
import 'package:currencies_pages/api/websocket.dart';
import 'package:currencies_pages/bloc/crypto/states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'events.dart';

class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  final notifCtrl = NotificationController.getInstance();
  CryptoBloc() : super(CryptoInitState());

  @override
  Stream<CryptoState> mapEventToState(event) async* {
    if(event is CryptoInitConnection) {
      try {
        yield CryptoLoading();
        await notifCtrl.initWebSocketConnection();
        final controller = notifCtrl.streamController;
        yield CryptoLoaded(streamController: controller, confirmationDetails: []);
      } catch(e) {
        print(e);
        print('crypto error caught');
        try {
          final cryptoList = await LocalDataProvider().getLocalCrypto();
          yield LocalCryptoLoaded(cryptoList: cryptoList);
        } catch (e) {
          print(e);
          yield CryptoError();
        }
      }
    }
    if(event is CryptoRemovePair) {
      yield CryptoLoading();
      final controller = notifCtrl.streamController;
      final pairs = notifCtrl.closeConnection(event.pair);
      yield CryptoLoaded(streamController: controller, confirmationDetails: pairs);
    }
    if(event is NotConfirmedRemovePair) {
      final controller = notifCtrl.streamController;
      yield CryptoLoaded(streamController: controller, confirmationDetails: []);
    }
    if(event is ConfirmedRemovePair) {
      notifCtrl.confirmedCloseConnection(event.pairs);
      final controller = notifCtrl.streamController;
      yield CryptoLoaded(streamController: controller, confirmationDetails: []);
    }
    if(event is GetLocalCrypto) {
      final cryptoList = await LocalDataProvider().getLocalCrypto();
      yield LocalCryptoLoaded(cryptoList: cryptoList);
    }
    if(event is CryptoCloseAllConnections) {
      notifCtrl.closeAllConnections();
    }
    if(event is RetryConnection) {
      try {
        await notifCtrl.initWebSocketConnection();
        // final controllers = notifCtrl.streamControllers;
        // yield CryptoLoaded(cryptoInfo: controllers);
      } catch(e) {
        print(e);
        try {
          final cryptoList = await LocalDataProvider().getLocalCrypto();
          yield LocalCryptoLoaded(cryptoList: cryptoList);
        } catch (e) {
          print(e);
          yield CryptoError();

        }
      }
    }
  }

}
import 'dart:async';
import 'package:currencies_pages/api/localData.dart';
import 'package:currencies_pages/api/websocket.dart';
import 'package:currencies_pages/bloc/crypto/states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'events.dart';

class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  final notifCtrl = NotificationController.getInstance();
  final LocalDataRepo localDataProvider = LocalDataProvider();
  CryptoBloc() : super(CryptoInitState());

  @override
  Stream<CryptoState> mapEventToState(event) async* {
    print(event);
    if(event is ReorderPair) {
      notifCtrl.reorderPair(event.newIdx, event.pair);
      localDataProvider.reorderPairs(event.newIdx, event.pair);
    }
    if(event is CheckIfObjIsEmpty) {
      final isEmpty = notifCtrl.isEmpty();

      if(isEmpty) {
        // yield CryptoEmpty();
      } else {
        final controller = notifCtrl.streamController;
        // yield CryptoLoaded(streamController: controller, confirmationDetails: []);
      }
    }
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
          final currencies = await LocalDataProvider().getLocalCurrencies();
          yield LocalCryptoLoaded(currencies: currencies);
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
      await notifCtrl.confirmedCloseConnection(event.pairs);
      final controller = notifCtrl.streamController;
      yield CryptoLoaded(streamController: controller, confirmationDetails: []);
    }
    if(event is GetLocalCrypto) {
      final currencies = await LocalDataProvider().getLocalCurrencies();
      yield LocalCryptoLoaded(currencies: currencies);
    }
    if(event is CryptoCloseAllConnections) {
      notifCtrl.closeAllConnections();
    }
    if(event is RetryConnection) {
      try {
        await notifCtrl.initWebSocketConnection();
      } catch(e) {
        print(e);
        try {
          final currencies = await LocalDataProvider().getLocalCurrencies();
          yield LocalCryptoLoaded(currencies: currencies);
        } catch (e) {
          print(e);
          yield CryptoError();

        }
      }
    }
  }

}
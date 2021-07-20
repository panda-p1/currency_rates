import 'dart:async';
import 'package:currencies_pages/api/localData.dart';
import 'package:currencies_pages/api/websocket.dart';
import 'package:currencies_pages/bloc/crypto/states.dart';
import 'package:currencies_pages/screens/home_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../constants.dart';
import 'events.dart';

class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  final notifCtrl = NotificationController.getInstance();
  final LocalDataRepo localDataProvider = LocalDataProvider();
  CryptoBloc() : super(CryptoInitState());

  @override
  Stream<CryptoState> mapEventToState(event) async* {
    print(event);
    if(event is ReorderPair) {
      localDataProvider.reorderPairs(event.newIdx, event.pair);
      // notifCtrl.reorderPair(event.newIdx, event.pair);
      // yield CryptoLoaded(streamControllers: notifCtrl.streamControllers);
    }
    if(event is LocalReorderPair) {
      await localDataProvider.reorderPairs(event.newIdx, event.pair);
      final reorderedCurrencies = await localDataProvider.getLocalCurrencies();
      // yield LocalCryptoLoaded(currencies: reorderedCurrencies);
    }
    if(event is CheckIfObjIsEmpty) {
      final isEmpty = notifCtrl.isEmpty();

      if(isEmpty) {
        yield CryptoEmpty();
      } else {
        final controllers = notifCtrl.streamControllers;
        yield CryptoLoaded(streamControllers: controllers);
      }
    }
    if(event is CryptoInitConnection) {
      try {
        yield CryptoLoading();
        await notifCtrl.initWebSocketConnection();
        final controllers = notifCtrl.streamControllers;
        yield CryptoLoaded(streamControllers: controllers);
      } catch(e) {
        print(e);
        print('crypto error caught');
        try {
          final currencies = await LocalDataProvider().getLocalCurrencies();
          yield LocalCryptoLoaded(currencies: currencies);
        } catch (e) {
          print(e);
          print('crypto error');
          yield CryptoError();
        }
      }
    }
    if(event is CryptoRemovePair) {
      yield CryptoModal(confirmationDetails: event.pair);
    }
    if(event is NotConfirmedRemovePair) {
      yield CryptoEmptyState();
    }
    if(event is ConfirmedRemovePair) {
      yield CryptoEmptyState();

      final pair = event.pair;
      localDataProvider.removePair(pair);
      notifCtrl.confirmedCloseConnection(pair);

      // if(event.requestFrom == Modal_RequestType.internet) {
      //   final controller = notifCtrl.streamControllers;
      // }
      // if(event.requestFrom == Modal_RequestType.local) {
      //   final currencies = await localDataProvider.getLocalCurrencies();
      //   yield LocalCryptoLoaded(currencies: currencies);
      // }
    }
    if(event is GetLocalCrypto) {
      final currencies = await localDataProvider.getLocalCurrencies();
      yield LocalCryptoLoaded(currencies: currencies);
    }
    if(event is CryptoCloseAllConnections) {
      notifCtrl.closeAllConnections();
    }
    if(event is RetryConnection) {
      try {
        print('retry connection');
        await notifCtrl.initWebSocketConnection();
        final controller = notifCtrl.streamControllers;
        yield CryptoLoaded(streamControllers: controller);
      } catch(e) {
        print(e);
        print('retry connection error');
        try {
          final currencies = await localDataProvider.getLocalCurrencies();
          yield LocalCryptoLoaded(currencies: currencies);
        } catch (e) {
          print(e);
          yield CryptoError();

        }
      }
    }
  }

}
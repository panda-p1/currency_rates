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
      notifCtrl.reorderPair(event.newIdx, event.pair);
    }
    if(event is LocalReorderPair) {
      await localDataProvider.reorderPairs(event.newIdx, event.pair);
      final reorderedCurrencies = await localDataProvider.getLocalCurrencies();
      yield LocalCryptoLoaded(currencies: reorderedCurrencies);
    }
    if(event is CheckIfObjIsEmpty) {
      final isEmpty = notifCtrl.isEmpty();

      if(isEmpty) {
        yield CryptoEmpty();
      } else {
        final controller = notifCtrl.streamController;
        yield CryptoLoaded(streamController: controller);
      }
    }
    if(event is CryptoInitConnection) {
      try {
        yield CryptoLoading();
        await notifCtrl.initWebSocketConnection();
        final controller = notifCtrl.streamController;
        yield CryptoLoaded(streamController: controller);
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
      List<Currency_Pairs>? pairs;
      if(event.requestFrom == Modal_RequestType.internet) {
        pairs = notifCtrl.showConnections(event.pair);
      }
      if(event.requestFrom == Modal_RequestType.local) {
        pairs = [event.pair];
      }
      yield CryptoModal(confirmationDetails: pairs!, requestFrom: event.requestFrom);
    }
    if(event is NotConfirmedRemovePair) {
      yield CryptoEmptyState();
    }
    if(event is ConfirmedRemovePair) {
      yield CryptoEmptyState();

      final pairs = event.pairs;

      if(event.requestFrom == Modal_RequestType.internet) {
        for(var pair in pairs) {
          await localDataProvider.removePair(pair);
        }

        await notifCtrl.confirmedCloseConnection(pairs);
        final controller = notifCtrl.streamController;
        yield CryptoLoaded(streamController: controller);
      }
      if(event.requestFrom == Modal_RequestType.local) {
        for(var pair in pairs) {
          await localDataProvider.removePair(pair);
        }
        final currencies = await localDataProvider.getLocalCurrencies();
        yield LocalCryptoLoaded(currencies: currencies);
      }
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
        final controller = notifCtrl.streamController;
        yield CryptoLoaded(streamController: controller);
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
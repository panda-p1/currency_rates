import 'dart:async';
import 'dart:io';

import 'package:currencies_pages/api/services.dart';
import 'package:currencies_pages/bloc/crypto/states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'events.dart';

class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  CryptoBloc() : super(CryptoInitState());

  @override
  Stream<CryptoState> mapEventToState(event) async* {
    if(event is CryptoInitConnection) {
      try {
        yield CryptoLoading();
        await NotificationController.getInstance().initWebSocketConnection();
        final controllers = NotificationController.getInstance().streamControllers;
        // print(controllers);
        yield CryptoLoaded(cryptoInfo: controllers);
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
    if(event is GetLocalCrypto) {
      final cryptoList = await LocalDataProvider().getLocalCrypto();
      yield LocalCryptoLoaded(cryptoList: cryptoList);
    }
    if(event is RetryConnection) {
      try {
        await NotificationController.getInstance().initWebSocketConnection();
        final controllers = NotificationController.getInstance().streamControllers;
        // print(controllers);
        yield CryptoLoaded(cryptoInfo: controllers);
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
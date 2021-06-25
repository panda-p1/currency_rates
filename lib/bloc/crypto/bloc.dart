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
    yield CryptoLoading();
    if(event is CryptoInitConnection) {
      try {
        await NotificationController.getInstance().initWebSocketConnection();
        final controllers = NotificationController.getInstance().streamControllers;
        // print(controllers);
        yield CryptoLoaded(cryptoInfo: controllers);
      } catch(e) {
        print(e);
        print('crypto error caught');
        yield CryptoError();
      }
    }
    if(event is CryptoRetryConnect) {

    }
  }

}
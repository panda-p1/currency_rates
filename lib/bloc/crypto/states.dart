import 'dart:async';
import 'package:currencies_pages/constants.dart';
import 'package:equatable/equatable.dart';
import 'package:currencies_pages/model/crypto.dart';

abstract class CryptoState extends Equatable {
  @override
  List<Object> get props => [];
}

class CryptoInitState extends CryptoState {
  CryptoInitState();
  @override
  List<Object> get props => [];
}

class CryptoLoading extends CryptoState {
  CryptoLoading();
  @override
  List<Object> get props => [];
}

class CryptoError extends CryptoState {
  CryptoError();
  @override
  List<Object> get props => [];
}

class CryptoLoaded extends CryptoState {
  final StreamController<Map<Currency_Pairs, Crypto?>> streamController;
  final List<Currency_Pairs> confirmationDetails;
  CryptoLoaded({required this.streamController, required this.confirmationDetails});
  @override
  List<Object> get props => [streamController, confirmationDetails];
}

class LocalCryptoLoaded extends CryptoState {
  final List<Crypto> cryptoList;
  LocalCryptoLoaded({required this.cryptoList});
  @override
  List<Object> get props => [cryptoList];
}
class CryptoRetryConnection extends CryptoState {
  final List<Crypto> cryptoList;
  CryptoRetryConnection({required this.cryptoList});
  @override
  List<Object> get props => [cryptoList];
}
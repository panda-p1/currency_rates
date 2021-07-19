import 'dart:async';
import 'package:currencies_pages/constants.dart';
import 'package:currencies_pages/screens/home_screen.dart';
import 'package:equatable/equatable.dart';
import 'package:currencies_pages/model/crypto.dart';

abstract class CryptoState extends Equatable {
  @override
  List<Object> get props => [];
}

class CryptoInitState extends CryptoState {
  @override
  List<Object> get props => [];
}

class CryptoClosingState extends CryptoState {
  @override
  List<Object> get props => [];
}

class CryptoLoading extends CryptoState {
  @override
  List<Object> get props => [];
}

class CryptoError extends CryptoState {
  @override
  List<Object> get props => [];
}

class CryptoLoaded extends CryptoState {
  final Map<String, StreamController<Crypto?>> streamControllers;
  CryptoLoaded({required this.streamControllers});
  @override
  List<Object> get props => [streamControllers];
}
class CryptoModal extends CryptoState {
  final String confirmationDetails;
  CryptoModal({required this.confirmationDetails});
  @override
  List<Object> get props => [confirmationDetails];
}
class ClosedCrypto extends CryptoState {
  @override
  List<Object> get props => [];
}
class CryptoEmptyState extends CryptoState { // created to change modal state
  @override
  List<Object> get props => [];
}
class LocalCryptoLoaded extends CryptoState {
  final Map<String, Crypto?> currencies;
  LocalCryptoLoaded({required this.currencies});
  @override
  List<Object> get props => [currencies];
}
class CryptoRetryConnection extends CryptoState {
  final List<Crypto> cryptoList;
  CryptoRetryConnection({required this.cryptoList});
  @override
  List<Object> get props => [cryptoList];
}

class CryptoEmpty extends CryptoState {
  @override
  List<Object> get props => [];
}


import 'package:currencies_pages/screens/home_screen.dart';
import 'package:equatable/equatable.dart';

import '../../constants.dart';

abstract class CryptoEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class CryptoInitConnection extends CryptoEvent {
  @override
  List<Object> get props => [];
}

class CryptoRetryConnect extends CryptoEvent {
  @override
  List<Object> get props => [];
}

class CryptoCloseAllConnections extends CryptoEvent {
  @override
  List<Object> get props => [];
}

class CryptoRemovePair extends CryptoEvent {
  final String pair;
  CryptoRemovePair({required this.pair});
  @override
  List<Object> get props => [pair];
}

class LocalNotConfirmedRemovePair extends CryptoEvent {
  @override
  List<Object> get props => [];
}
class NotConfirmedRemovePair extends CryptoEvent {
  @override
  List<Object> get props => [];
}

class ConfirmedRemovePair extends CryptoEvent {
  final String pair;
  ConfirmedRemovePair({required this.pair});
  @override
  List<Object> get props => [pair];
}
class ConfirmedLocalRemovePair extends CryptoEvent {
  final List<Currency_Pairs> pairs;
  ConfirmedLocalRemovePair({required this.pairs});
  @override
  List<Object> get props => [pairs];
}

class GetLocalCrypto extends CryptoEvent {
  @override
  List<Object> get props => [];
}

class RetryConnection extends CryptoEvent {
  @override
  List<Object> get props => [];
}

class LocalReorderPair extends CryptoEvent {
  final int newIdx;
  final String pair;
  LocalReorderPair({required this.newIdx, required this.pair});
  @override
  List<Object> get props => [newIdx, pair];
}

class ReorderPair extends CryptoEvent {
  final int newIdx;
  final String pair;
  ReorderPair({required this.newIdx, required this.pair});
  @override
  List<Object> get props => [newIdx, pair];
}


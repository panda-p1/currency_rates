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
  final Currency_Pairs pair;
  CryptoRemovePair({required this.pair});
  @override
  List<Object> get props => [pair];
}

class NotConfirmedRemovePair extends CryptoEvent {
  @override
  List<Object> get props => [];
}

class ConfirmedRemovePair extends CryptoEvent {
  final List<Currency_Pairs> pairs;
  ConfirmedRemovePair({required this.pairs});
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

class ReorderPair extends CryptoEvent {
  final int newIdx;
  final Currency_Pairs pair;
  ReorderPair({required this.newIdx, required this.pair});
  @override
  List<Object> get props => [newIdx, pair];
}

class CheckIfObjIsEmpty extends CryptoEvent {
  @override
  List<Object> get props => [];
}


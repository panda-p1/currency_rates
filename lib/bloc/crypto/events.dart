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
  final Currency_Pairs pair;
  final Modal_RequestType requestFrom;
  CryptoRemovePair({required this.pair,required this.requestFrom});
  @override
  List<Object> get props => [pair, requestFrom];
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
  final List<Currency_Pairs> pairs;
  final Modal_RequestType requestFrom;
  ConfirmedRemovePair({required this.pairs, required this.requestFrom});
  @override
  List<Object> get props => [pairs, requestFrom];
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


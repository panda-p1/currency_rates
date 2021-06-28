import 'package:currencies_pages/model/currencies.dart';
import 'package:currencies_pages/screens/home_screen.dart';
import 'package:equatable/equatable.dart';

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
  List<Object> get props => [];
}

class GetLocalCrypto extends CryptoEvent {
  @override
  List<Object> get props => [];
}

class RetryConnection extends CryptoEvent {
  @override
  List<Object> get props => [];
}


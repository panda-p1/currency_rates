import 'package:currencies_pages/model/currencies.dart';
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
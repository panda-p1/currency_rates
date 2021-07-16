import 'package:currencies_pages/constants.dart';
import 'package:currencies_pages/model/currencies.dart';
import 'package:currencies_pages/model/crypto.dart';
import 'package:equatable/equatable.dart';

abstract class LocalDataEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class ChangeTheme extends LocalDataEvent {
  @override
  List<Object> get props => [];
}
class GetTheme extends LocalDataEvent {
  @override
  List<Object> get props => [];
}
class DecreaseDelay extends LocalDataEvent {
  @override
  List<Object> get props => [];
}
class IncreaseDelay extends LocalDataEvent {
  @override
  List<Object> get props => [];
}

class GetDelay extends LocalDataEvent {
  @override
  List<Object> get props => [];
}

// class StoreCrypto extends LocalDataEvent {
//   final Crypto crypto;
//   StoreCrypto({required this.crypto});
//   @override
//   List<Object> get props => [crypto];
// }

class StoreCurrencies extends LocalDataEvent {
  final Map<String, Crypto?> currencies;
  StoreCurrencies({required this.currencies});
  @override
  List<Object> get props => [currencies];
}


// class StoreCurrencies extends LocalDataEvent {
//   final Currencies currencies;
//   StoreCurrencies({required this.currencies});
//   @override
//   List<Object> get props => [currencies];
// }

class GetLocalCurrencies extends LocalDataEvent {
  @override
  List<Object> get props => [];
}

class ReturnConnectionBody extends LocalDataEvent {
  @override
  List<Object> get props => [];
}

class GetAvailableToAddPairs extends LocalDataEvent {
  @override
  List<Object> get props => [];
}

class AddPair extends LocalDataEvent {
  final String pair;
  AddPair({required this.pair});
  @override
  List<Object> get props => [pair];
}

class RemovePair extends LocalDataEvent {
  final String pair;
  RemovePair({required this.pair});
  @override
  List<Object> get props => [pair];
}

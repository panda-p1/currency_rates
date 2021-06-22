import 'package:currencies_pages/model/currencies.dart';
import 'package:equatable/equatable.dart';

enum LocalDataEvent1 {
  changeTheme,
  getTheme,
  decreaseDelay,
  increaseDelay,
  getDelay
}

class LocalDataEvent extends Equatable {
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

class StoreCurrencies extends LocalDataEvent {
  final Currencies currencies;
  StoreCurrencies({required this.currencies});
  @override
  List<Object> get props => [currencies];
}

class GetLocalCurrencies extends LocalDataEvent {
  @override
  List<Object> get props => [];
}

class ReturnConnectionBody extends LocalDataEvent {
  @override
  List<Object> get props => [];
}

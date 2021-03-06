import 'package:currencies_pages/model/currencies.dart';
import 'package:currencies_pages/model/graphic_price.dart';
import 'package:currencies_pages/model/ticker_details.dart';
import 'package:equatable/equatable.dart';

abstract class CurrenciesState extends Equatable {
  @override
  List<Object> get props => [];
}

class CurrenciesInitState extends CurrenciesState {
  CurrenciesInitState();
  @override
  List<Object> get props => [];
}

class CurrenciesLoading extends CurrenciesState {
  CurrenciesLoading();
  @override
  List<Object> get props => [];
}
class CurrencyDetails extends CurrenciesState {
  final TickerDetails details;
  CurrencyDetails({required this.details});
  @override
  List<Object> get props => [];
}
class CurrencyDetailsLoading extends CurrenciesState {
  CurrencyDetailsLoading();
  @override
  List<Object> get props => [];
}

class CurrenciesNotInTime extends CurrenciesState {
  CurrenciesNotInTime();
  @override
  List<Object> get props => [];
}

class LostConnection extends CurrenciesState {
  LostConnection();
  @override
  List<Object> get props => [];
}

class CurrenciesLoaded extends CurrenciesState {
  final BinanceRestCurrencies currencies;
  CurrenciesLoaded({required this.currencies});
  @override
  List<Object> get props => [currencies];
}

class LocalCurrenciesLoaded extends CurrenciesState {
  final BinanceRestCurrencies currencies;
  LocalCurrenciesLoaded({required this.currencies});
  @override
  List<Object> get props => [currencies];
}

class GraphicPriceLoaded extends CurrenciesState {
  final List<GraphicPrice> prices;
  GraphicPriceLoaded({required this.prices});
  @override
  List<Object> get props => [prices];
}

class CurrenciesError extends CurrenciesState {
  final String message;
  CurrenciesError({required this.message});
}

class LocalCurrenciesError extends CurrenciesState {}


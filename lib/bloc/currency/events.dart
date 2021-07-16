import 'package:equatable/equatable.dart';

abstract class CurrenciesEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class GetRate extends CurrenciesEvent {
  @override
  List<Object> get props => [];
}

class GetBinance extends CurrenciesEvent {
  @override
  List<Object> get props => [];
}

class GetGraphicPrice extends CurrenciesEvent {
  final String ticker;
  final String interval;
  final int startDate;
  GetGraphicPrice({required this.ticker, required this.interval, required this.startDate});
  @override
  List<Object> get props => [ticker, interval, startDate];
}

class GetTickerDetails extends CurrenciesEvent {
  final String tickerName;
  GetTickerDetails({required this.tickerName});
  @override
  List<Object> get props => [tickerName];
}

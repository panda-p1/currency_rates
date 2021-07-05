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
  GetGraphicPrice({required this.ticker});
  @override
  List<Object> get props => [];
}

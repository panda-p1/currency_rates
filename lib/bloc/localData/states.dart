import 'package:currencies_pages/model/currencies.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class LocalDataState extends Equatable {
  @override
  List<Object> get props => [];
}

class LocalDataInitState extends LocalDataState {
  LocalDataInitState();
  @override
  List<Object> get props => [];
}

class ThemeLoading extends LocalDataState {
  ThemeLoading();
  @override
  List<Object> get props => [];
}
class DelayLoading extends LocalDataState {
  DelayLoading();
  @override
  List<Object> get props => [];
}
class DelayLoaded extends LocalDataState {
  final double delay;
  DelayLoaded({required this.delay});
  @override
  List<Object> get props => [delay];
}

class ThemeLoaded extends LocalDataState {
  final ThemeData theme;
  ThemeLoaded({required this.theme});
  @override
  List<Object> get props => [theme];
}

class GetLocalCurrenciesError extends LocalDataState {}

class StoreCurrenciesError extends LocalDataState {}

class LocalCurrencies extends LocalDataState {
  final Currencies currencies;
  LocalCurrencies({required this.currencies});
}

class ConnectionResumed extends LocalDataState {}
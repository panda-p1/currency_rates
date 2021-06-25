import 'dart:async';

import 'package:equatable/equatable.dart';

abstract class CryptoState extends Equatable {
  @override
  List<Object> get props => [];
}

class CryptoInitState extends CryptoState {
  CryptoInitState();
  @override
  List<Object> get props => [];
}

class CryptoLoading extends CryptoState {
  CryptoLoading();
  @override
  List<Object> get props => [];
}

class CryptoError extends CryptoState {
  CryptoError();
  @override
  List<Object> get props => [];
}

class CryptoLoaded extends CryptoState {
  final List<StreamController> cryptoInfo;
  CryptoLoaded({required this.cryptoInfo});
  @override
  List<Object> get props => [];
}
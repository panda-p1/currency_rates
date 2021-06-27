import 'package:currencies_pages/api/services.dart';
import 'package:currencies_pages/bloc/localData/states.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'events.dart';

class LocalDataBloc extends Bloc<LocalDataEvent, LocalDataState> {
  static LocalDataBloc? _instance;
  static LocalDataBloc getInstance() {
    if(LocalDataBloc._instance == null) {
      LocalDataBloc._instance = LocalDataBloc(localDataRepo: LocalDataProvider());
    } else {
    }
    return LocalDataBloc._instance!;
  }

  final LocalDataRepo localDataRepo;

  LocalDataBloc({required this.localDataRepo}) : super(LocalDataInitState());
  @override
  mapEventToState(event) async* {
    if(event is DecreaseDelay) {
      try {
        final delay = await localDataRepo.changeDelay('-');
        yield DelayLoaded(delay: delay);
      } catch (e) {
        print(e);
      }
    }
    if(event is IncreaseDelay) {
      try {
        final delay = await localDataRepo.changeDelay('+');
        yield DelayLoaded(delay: delay);
      } catch (e) {
          print(e);
      }
    }
    if(event is GetDelay) {
      try {
        final delay = await localDataRepo.getDelay();
        yield DelayLoaded(delay: delay);
      } catch (e) {
        print(e);
      }
    }
    if(event is ChangeTheme) {
      final theme = await localDataRepo.changeTheme();
      yield ThemeLoaded(theme: theme);
    }
    if(event is GetTheme) {
      final theme = await localDataRepo.getTheme();
      yield ThemeLoaded(theme: theme);
    }
    if(event is StoreCurrencies) {
      try {
        localDataRepo.storeCurrencies(event.currencies);
      } catch(e) {
        print(e);
        yield StoreCurrenciesError();
      }
    }
    if(event is StoreCrypto) {
      try {
        localDataRepo.storeCrypto(event.crypto);
      } catch(e) {
        print(e);
        yield StoreCurrenciesError();
      }
    }
    if(event is GetLocalCurrencies) {
      try {
        final currencies = await localDataRepo.getLocalCurrencies();
        yield LocalCurrencies(currencies: currencies);
      } catch(e) {
        print(e);
        yield GetLocalCurrenciesError();
      }
    }
    if(event is ReturnConnectionBody) {
      yield ConnectionResumed();
    }
  }
}
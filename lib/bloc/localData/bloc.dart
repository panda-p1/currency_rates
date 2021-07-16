import 'package:currencies_pages/api/localData.dart';
import 'package:currencies_pages/api/websocket.dart';
import 'package:currencies_pages/bloc/localData/states.dart';
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
    if(event is RemovePair) {
      NotificationController.getInstance().confirmedCloseConnection(event.pair);
      // localDataRepo.removePair(event.pair);
    }
    if(event is AddPair) {
      print('add pair event localdata bloc');
      NotificationController.getInstance().addPair(event.pair);
      await localDataRepo.addPair(event.pair);
    }
    if(event is GetAvailableToAddPairs) {
      final pairs = await localDataRepo.getAvailableToAddPairs();
      yield AvailableToAddPairs(pairs: pairs);
    }
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

    if(event is GetLocalCurrencies) {
      try {
        final currencies = await localDataRepo.getLocalCurrencies();
        // yield LocalCurrencies(currencies: currencies);
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
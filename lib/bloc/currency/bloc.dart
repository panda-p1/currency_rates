import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:currencies_pages/api/currenciesProvider.dart';
import 'package:currencies_pages/api/localData.dart';
import 'package:currencies_pages/bloc/currency/states.dart';
import 'package:currencies_pages/bloc/currency/events.dart';

class CurrenciesBloc extends Bloc<CurrenciesEvents, CurrenciesState> {
  final CurrencyRepo currencyRepo;
  CurrenciesBloc({required this.currencyRepo}) : super(CurrenciesInitState());

  @override
  Stream<CurrenciesState> mapEventToState(CurrenciesEvents event,) async* {
    switch(event) {
      case CurrenciesEvents.initGetRate:
        try {
          yield CurrenciesLoading();
          final currencies = await currencyRepo.getRates(3);
          yield CurrenciesLoaded(currencies: currencies);
        } on TimeoutException {
          try {
            print('timeout exception');
            final currencies = await LocalDataProvider().getLocalCurrencies();
            // yield LocalCurrenciesLoaded(currencies: currencies);
          } catch (e) {
            print(e);
            yield LocalCurrenciesError();
          }
        } on SocketException {
          try {
            print('timeout exception');
            final currencies = await LocalDataProvider().getLocalCurrencies();
            // yield LocalCurrenciesLoaded(currencies: currencies);
          } catch (e) {
            print(e);
            yield LocalCurrenciesError();
          }
        }
        catch (e) {
          print('get tree error -------------------');
          print(e);
        }
        break;
      case CurrenciesEvents.getRate:
        try {
          final currencies = await currencyRepo.getRates(3);
          yield CurrenciesLoaded(currencies: currencies);
        } on TimeoutException {
          try {
            print('timeout exception');
            final currencies = await LocalDataProvider().getLocalCurrencies();
            // yield LocalCurrenciesLoaded(currencies: currencies);
          } catch (e) {
            print(e);
            yield LocalCurrenciesError();
          }
        } on SocketException {
          try {
            print('timeout exception');
            final currencies = await LocalDataProvider().getLocalCurrencies();
            // yield LocalCurrenciesLoaded(currencies: currencies);
          } catch (e) {
            print(e);
            yield LocalCurrenciesError();
          }
        }
        catch (e) {
          print('get tree error -------------------');
          print(e);
        }
        break;
    }

  }
}

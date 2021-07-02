import 'dart:convert';
import 'package:currencies_pages/model/currencies.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'localData.dart';

abstract class CurrencyRepo {
  Future<BinanceRestCurrencies> getBinance();
}

class CurrencyProvider implements CurrencyRepo {
  @override
  Future<BinanceRestCurrencies> getBinance() async {
    final response = await http.get(Uri.parse('https://api.binance.com/api/v3/exchangeInfo'));
    final delay = await LocalDataProvider().getDelay();
    if(response.statusCode == 200) {

      return BinanceRestCurrencies.fromJson({...jsonDecode(response.body) as Map, ...{"delay": delay}, ...{"time": DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now())}});
    } else {
      throw Exception('get binance code != 200');
    }
  }
}

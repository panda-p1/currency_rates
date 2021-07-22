import 'dart:convert';
import 'package:currencies_pages/model/currencies.dart';
import 'package:currencies_pages/model/graphic_price.dart';
import 'package:currencies_pages/model/ticker_details.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'localData.dart';

abstract class CurrencyRepo {
  Future<BinanceRestCurrencies> getBinance();
  Future<List<GraphicPrice>> getGraphicPrice(String tickerName, String interval, int startDate);
  Future<TickerDetails> getDetailTickerInfo(String tickerName);
}

class CurrencyProvider implements CurrencyRepo {
  @override
  Future<BinanceRestCurrencies> getBinance() async {
    final response = await http.get(Uri.parse('https://api.binance.com/api/v3/exchangeInfo'));
    final delay = await LocalDataProvider().getDelay();
    if(response.statusCode == 200) {
      return BinanceRestCurrencies.fromJson({...jsonDecode(response.body) as Map, ...{"delay": delay}, ...{"time": DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now())}});
    } else {
      throw Exception('get binance status code != 200');
    }
  }

  Future<List<GraphicPrice>> getGraphicPrice(String tickerName, String interval, int startDate) async {
    final response = await http.get(Uri.parse('https://api.binance.com/api/v3/klines?symbol=$tickerName&interval=$interval&startTime=$startDate'));
    final pricesList = jsonDecode(response.body) as List;
    return pricesList.map<GraphicPrice>((e) {
      return GraphicPrice(time: DateTime.fromMillisecondsSinceEpoch(e[0]), open: e[1], close: e[4]);
    }).toList();
  }
  Future<TickerDetails> getDetailTickerInfo(String tickerName) async {
    final response = await http.get(Uri.parse('https://api.binance.com/api/v3/ticker/24hr'));
    final details = jsonDecode(response.body) as List;
    return TickerDetails.fromJson(details.where((element) => element['symbol'] == tickerName).toList()[0]);
  }
}

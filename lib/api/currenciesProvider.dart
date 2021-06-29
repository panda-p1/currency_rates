import 'dart:convert';

import 'package:currencies_pages/model/currencies.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'localData.dart';

abstract class CurrencyRepo {
  Future<Currencies> getRates(double timeout);
}

class CurrencyProvider implements CurrencyRepo {
  @override
  Future<Currencies> getRates(double timeout) async {
    final response = await http.get(Uri.parse('http://kursorub.com/rest/data?cis=8&v=40&sa=0&t=162392525514'))
        .timeout(Duration(milliseconds: (timeout * 1000).toInt()));
    final delay = await LocalDataProvider().getDelay();
    return Currencies.fromJson({...jsonDecode(response.body) as Map, ...{"delay": delay}, ...{"time": DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now())}});
  }
}

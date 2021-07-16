import 'dart:async';

import 'package:currencies_pages/bloc/crypto/bloc.dart';
import 'package:currencies_pages/bloc/crypto/events.dart';
import 'package:currencies_pages/bloc/crypto/states.dart';
import 'package:currencies_pages/bloc/currency/bloc.dart';
import 'package:currencies_pages/bloc/currency/events.dart';
import 'package:currencies_pages/bloc/currency/states.dart';
import 'package:currencies_pages/model/graphic_price.dart';
import 'package:currencies_pages/model/crypto.dart';
import 'package:currencies_pages/model/ticker_details.dart';
import 'package:currencies_pages/widgets/horizontal_currency.dart';
import 'package:currencies_pages/widgets/interval_button.dart';

import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../constants.dart';
import '../styles.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class SDI {
  final int date;
  final String interval;
  SDI({required this.date, required this.interval});
}

Map<String, SDI> INTERVAL_DATE = {
  '15m': SDI(date: DateTime.now().subtract(Duration(minutes: 15)).millisecondsSinceEpoch, interval: '1m' ),
  '1H': SDI(date: DateTime.now().subtract(Duration(hours: 1)).millisecondsSinceEpoch, interval: '1m' ),
  '2H': SDI(date: DateTime.now().subtract(Duration(hours: 2)).millisecondsSinceEpoch, interval: '1m' ),
  '6H': SDI(date: DateTime.now().subtract(Duration(hours: 6)).millisecondsSinceEpoch, interval: '3m' ),
  '12H': SDI(date: DateTime.now().subtract(Duration(hours: 12)).millisecondsSinceEpoch, interval: '5m' ),
  '1D': SDI(date: DateTime.now().subtract(Duration(days: 1)).millisecondsSinceEpoch, interval: '15m' ),
  '7D': SDI(date: DateTime.now().subtract(Duration(days: 7)).millisecondsSinceEpoch, interval: '1h' ),
  '30D': SDI(date: DateTime.now().subtract(Duration(days: 30)).millisecondsSinceEpoch, interval: '4h' ),
  '1Y': SDI(date: DateTime.now().subtract(Duration(days: 356)).millisecondsSinceEpoch, interval: '1d' ),
};

class CurrencyGraphic extends StatefulWidget {
  final Crypto crypto;
  final StreamController<Crypto?>? streamController;
  CurrencyGraphic({Key? key, required this.crypto, required this.streamController}) : super(key: key);

  @override
  _CurrencyGraphicState createState() => _CurrencyGraphicState();
}

class _CurrencyGraphicState extends State<CurrencyGraphic> {
  int pressedBtnIdx = 0;

  @override
  void initState() {
    _getGraphicPrice();
    _getTickerDetails();
    super.initState();
  }
  void _getTickerDetails() {
    context.read<CurrenciesBloc>().add(GetTickerDetails(tickerName: widget.crypto.queryName));
  }
  void _getGraphicPrice() {
    final SDI = INTERVAL_DATE.values.toList()[pressedBtnIdx];
    context.read<CurrenciesBloc>().add(GetGraphicPrice(
        ticker: widget.crypto.queryName,
        interval: SDI.interval,
        startDate: SDI.date
    ));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
            preferredSize: Size.fromHeight(LayoutStyles.appbarHeight),
            child: AppBar(
              title: Text("Graphic"),
            )
        ),
      body: _body(),
    );
  }
  Widget _body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _header(),
        _rowButtons(),
        _bodyUI(),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,

          child: widget.streamController != null
              ?
            StreamBuilder<Crypto?>(
                stream: widget.streamController!.stream,
                builder: (_, snapshot) {
                  if(!snapshot.hasData) {
                    return Container();
                  }
                  final crypto = snapshot.data!;
                  if(crypto == null) {
                    return Container();
                  }
                  return HorizontalCurrencyWidget(
                      currencyPrice: crypto.price,
                      currencyName: crypto.name
                  );
                }
            )
            : Container()
        ),
      ),
    );
  }
  _onIntervalButtonClick(String btnText) {
    if(pressedBtnIdx != INTERVAL_DATE.keys.toList().indexOf(btnText)) {
      setState(() {
        pressedBtnIdx = INTERVAL_DATE.keys.toList().indexOf(btnText);
      });
      _getGraphicPrice();
    }
  }
  Widget _rowButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        children: INTERVAL_DATE.keys.toList().map((e) {
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IntervalButton(
              onClick: () => _onIntervalButtonClick(e), text: e, clicked: INTERVAL_DATE.keys.toList().indexOf(e) == pressedBtnIdx,),
          );
        }).toList(),
      ),
    );
  }

  Widget _bodyUI() {
    return Column(
      children: [
        _graphic(),
        _details()
      ],
    );
  }
  Widget _details() {
    return BlocBuilder<CurrenciesBloc, CurrenciesState>(builder: (BuildContext context, CurrenciesState state) {
      if(state is CurrencyDetails) {
        return _detailsUI(state.details);
      }

      if(state is CurrenciesError) {
        return Container(
            child: Text(
              'error',
              style: TextStyle(color: Colors.red),
            )
        );
      }
      return Container();
    }, buildWhen: (state1, state2) => state2 is CurrencyDetailsLoading || state2 is CurrencyDetails,);
  }

  Widget _detailsUnit(String text, String price) {
    return Padding(
      padding: const EdgeInsets.only(right: 4.0, bottom: 4),
      child: Row(
        children: [
          Text(text, style: TextStyle(fontSize: 15, color: Colors.grey[600]),),
          Spacer(),
          Text(_format(price), style: TextStyle(fontSize: 15))
        ],
      ),
    );
  }

  Widget _detailsUI(TickerDetails details) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.9,

      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _detailsUnit('Open', details.openPrice),
                _detailsUnit('High', details.highPrice),
                _detailsUnit('Low', details.lowPrice),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailsUnit('Vol', details.volume)
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _graphic() {
    return BlocBuilder<CurrenciesBloc, CurrenciesState>(builder: (BuildContext context, CurrenciesState state) {
      print(state);
      if(state is GraphicPriceLoaded) {
        return _graphicUI(state.prices);
      }
      if(state is CurrenciesLoading) {
        return _loader();
      }
      if(state is CurrenciesError) {
        return Container(
            child: Text(
              'error',
              style: TextStyle(color: Colors.red),
            )
        );
      }
      return Container();
    }, buildWhen: (state1, state2) => state2 is! CurrencyDetailsLoading && state2 is! CurrencyDetails,);
  }

  SizedBox _sized({required Widget child}) {
    return SizedBox(
        height: MediaQuery.of(context).size.height / 2.5,
        width: MediaQuery.of(context).size.width * 0.9,
        child: child,
    );
  }

  Widget _loader() {
    return _sized(
      child: Center(child: CircularProgressIndicator(),),
    );
  }

  Widget _graphicUI(List<GraphicPrice> priceList) {
    return _sized(
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(),
        series: [
          LineSeries<GraphicPrice, DateTime>(
              dataSource: priceList,
              xValueMapper: (GraphicPrice sales, _) => sales.time,
              yValueMapper: (GraphicPrice sales, _) => double.parse(sales.price),
          ),
        ],
      ),
    );
  }
}
String _format(String price) {
  return NumberFormat.currency(locale: 'eu', symbol: '').format(double.parse(price));
}
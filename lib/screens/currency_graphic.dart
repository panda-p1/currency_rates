import 'dart:async';

import 'package:currencies_pages/bloc/currency/bloc.dart';
import 'package:currencies_pages/bloc/currency/events.dart';
import 'package:currencies_pages/bloc/currency/states.dart';
import 'package:currencies_pages/model/graphic_price.dart';
import 'package:currencies_pages/model/crypto.dart';
import 'package:currencies_pages/widgets/currency_widget.dart';
import 'package:currencies_pages/widgets/horizontal_currency.dart';
import 'package:currencies_pages/widgets/interval_button.dart';

import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants.dart';
import '../styles.dart';
import 'package:charts_flutter/flutter.dart' as charts;

const INTERVALS = {
  '1H': '1h',
  '2H': '2h',
  '6H': '6h',
  '12H': '12h',
  '1D': '1d',
  '7D': '1w',
  '30D': '1M',
  '1Y': ''
};

class SDI {
  final int date;
  final String interval;
  SDI({required this.date, required this.interval});
}

Map<String, SDI> INTERVAL_DATE = {
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
  final StreamController<Map<Currency_Pairs, Crypto?>>? streamController;
  CurrencyGraphic({Key? key, required this.crypto, required this.streamController}) : super(key: key);

  @override
  _CurrencyGraphicState createState() => _CurrencyGraphicState();
}

class _CurrencyGraphicState extends State<CurrencyGraphic> {
  int pressedBtnIdx = 5;
  double min = 0;
  double max = 0;

  @override
  void initState() {
    getGraphicPrice();
    super.initState();
  }
  void getGraphicPrice() {
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
            StreamBuilder<Map<Currency_Pairs, Crypto?>>(
                stream: widget.streamController!.stream,
                builder: (_, snapshot) {
                  if(!snapshot.hasData) {
                    return Container();
                  }
                  final crypto = snapshot.data![widget.crypto.type];
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
      getGraphicPrice();
    }
  }
  Widget _rowButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Wrap(
        children: INTERVALS.keys.toList().map((e) {
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IntervalButton(
              onClick: () => _onIntervalButtonClick(e), text: e, clicked: INTERVALS.keys.toList().indexOf(e) == pressedBtnIdx,),
          );
        }).toList(),
      ),
    );
  }
  Widget _bodyUI() {
    return BlocBuilder<CurrenciesBloc, CurrenciesState>(builder: (BuildContext context, CurrenciesState state) {
      if(state is GraphicPriceLoaded) {
        min = state.prices.map((e) => double.parse(e.price)).reduce(math.min);
        max = state.prices.map((e) => double.parse(e.price)).reduce(math.max);
        return _graphic(state.prices);
      }
      if(state is CurrenciesLoading) {
        return _loader();
      }
      if(state is CurrenciesError) {
        return Container(
            child: Text(
              state.message,
              style: TextStyle(color: Colors.red),
            )
        );
      }
      return Container();
    });
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

  Widget _graphic(List<GraphicPrice> prices) {
    prices.forEach((element) {
      print(element.time);
    });
    print(prices.length);
    return _sized(
      child: charts.TimeSeriesChart(

        [
          charts.Series<GraphicPrice, DateTime>(

            id: widget.crypto.queryName,
            colorFn: (_, __) => charts.ColorUtil.fromDartColor(Theme.of(context).textTheme.bodyText1!.color!),
            domainFn: (GraphicPrice sales, _) => sales.time,
            measureFn: (GraphicPrice sales, _) => num.parse(sales.price),
            data: prices,
          ),
        ],
        domainAxis: charts.DateTimeAxisSpec(
          renderSpec: charts.GridlineRendererSpec(
              labelStyle: charts.TextStyleSpec(
                fontSize: 10,
                color: charts.ColorUtil.fromDartColor(Theme.of(context).textTheme.bodyText1!.color!),
              ),

          ),
        ),
        primaryMeasureAxis: charts.NumericAxisSpec(
          tickProviderSpec: charts.BasicNumericTickProviderSpec(zeroBound: false),
          renderSpec: charts.GridlineRendererSpec(
            labelStyle: charts.TextStyleSpec(
              fontSize: 10,
              color: charts.ColorUtil.fromDartColor(Theme.of(context).textTheme.bodyText1!.color!),
            ),
            // lineStyle: charts.LineStyleSpec(
            //   color: charts.MaterialPalette.gray.shadeDefault,
            // )
          ),
        ),
      ),
    );
  }
}

import 'package:currencies_pages/bloc/currency/bloc.dart';
import 'package:currencies_pages/bloc/currency/events.dart';
import 'package:currencies_pages/bloc/currency/states.dart';
import 'package:currencies_pages/model/graphic_price.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/src/provider.dart';

import '../styles.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class CurrencyGraphic extends StatefulWidget {
  final String tickerName;
  CurrencyGraphic({Key? key, required this.tickerName}) : super(key: key);

  @override
  _CurrencyGraphicState createState() => _CurrencyGraphicState();
}

class _CurrencyGraphicState extends State<CurrencyGraphic> {

  @override
  void initState() {
    initGraphicPrice();
    super.initState();
  }
  void initGraphicPrice() {
    context.read<CurrenciesBloc>().add(GetGraphicPrice(ticker: widget.tickerName));
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
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(widget.tickerName),
        BlocBuilder<CurrenciesBloc, CurrenciesState>(builder: (BuildContext context, CurrenciesState state) {
          if(state is GraphicPriceLoaded) {
            return _graphic(state.prices);
          }
          return Container();
        })
      ],
    );
  }

  Widget _graphic(List<GraphicPrice> prices) {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 2,
      child: charts.TimeSeriesChart(
          [
            charts.Series<GraphicPrice, DateTime>(
              displayName: 'NAME',
              id: 'Sales',
              colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
              domainFn: (GraphicPrice sales, _) => sales.time,
              measureFn: (GraphicPrice sales, _) => num.parse(sales.price),
              data: prices,

            )
          ]
      ),
    );
  }
}

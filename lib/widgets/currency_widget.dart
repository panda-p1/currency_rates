import 'dart:async';

import 'package:currencies_pages/model/graphic_price.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../styles.dart';

class CurrencyWidget extends StatefulWidget {
  final String? currencyName;
  final String currencyPrice;
  final CurrencyStyles styles;
  final bool? deleteIcon;
  final Function? onDeleteIconPress;
  final String? percent;
  CurrencyWidget({Key? key,
    this.deleteIcon, this.onDeleteIconPress,
    this.currencyName, this.percent,
    required this.currencyPrice,
    required this.styles}) : super(key: key);
  @override
  State<CurrencyWidget> createState() => _CurrencyWidgetState();
}
class _CurrencyWidgetState extends State<CurrencyWidget> with TickerProviderStateMixin {
  late Timer _timer;
  Color? color;
  String? previousPrice;
  bool animate = false;
  ChartSeriesController? _chartSeriesController;

  //Initialize the data source
  List<GraphicPrice> chartData = [];

  @override
  void didUpdateWidget(oldWidget) {
    if(oldWidget.currencyPrice != widget.currencyPrice) {

      chartData.add(GraphicPrice(time: DateTime.now(), open: widget.currencyPrice, close: widget.currencyPrice));

      if(chartData.length == 20) {
        chartData.removeAt(0);
        _chartSeriesController!.updateDataSource(
          addedDataIndexes: <int>[chartData.length - 1],
          removedDataIndexes: <int>[0],
        );
      } else {
        _chartSeriesController?.updateDataSource(
          addedDataIndexes: <int>[chartData.length - 1],
        );
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  SfCartesianChart _buildLiveLineChart() {
    return SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: DateTimeAxis(),
        primaryYAxis: NumericAxis(
            axisLine: const AxisLine(width: 0),
            majorTickLines: const MajorTickLines(size: 0)),
        series: <LineSeries<GraphicPrice, DateTime>>[
          LineSeries<GraphicPrice, DateTime>(
            onRendererCreated: (ChartSeriesController controller) {
              _chartSeriesController = controller;
            },
            dataSource: chartData,
            color: const Color.fromRGBO(192, 108, 132, 1),
            xValueMapper: (GraphicPrice sales, _) => sales.time,
            yValueMapper: (GraphicPrice sales, _) => double.parse(sales.price),
            animationDuration: 0,
          )
        ]);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
  @override
  void initState() {
    _timer = Timer(Duration(milliseconds: 400), () {
      _timer.cancel();
    });
    super.initState();
  }


  _callback() {
    if(previousPrice != null) {
      final pp = double.parse(previousPrice!);
      final cp = double.parse(widget.currencyPrice);
      if(pp < cp) {
        _timer = Timer(Duration(milliseconds: 400), () {
          _timer.cancel();
        });
        color = Colors.green;
      } else {
        if(pp == cp) {
          color = null;
        } else {
          color = Colors.red;
          _timer = Timer(Duration(milliseconds: 400), () {
            _timer.cancel();
          });
        }
      }
    }
    previousPrice = widget.currencyPrice;
  }
  @override
  Widget build(BuildContext context) {
    if(!_timer.isActive) {
      _callback();
    }
    return SizedBox(
      // height: widget.styles.currencyWidgetHeight() + 1,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _currencyName(),
                Spacer(),
                _currencyPrice(),
              ],
            ),
          ),
          _buildLiveLineChart(),
          Divider(),
        ],
      ),
    );
  }

  Widget _currencyName() {
    if(widget.currencyName == null) {
      return Container();
    }
    return Stack(
      clipBehavior: Clip.none, children: [
      Row(
        // crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.currencyName!,
            style: TextStyle(
                fontSize: widget.styles.currencyNameFontSize(),
                color: widget.styles.currencyNameFontColor()),),

        ],
      ),
      if(widget.deleteIcon != null && widget.deleteIcon!)
        Positioned(
            right: -20,
            top: -15,
            child: IconButton(
              icon: Icon(Icons.remove_circle_sharp, color: Colors.red, size: 30),
              onPressed: () => widget.onDeleteIconPress!(),))
    ],
    );
  }
  Widget _currencyPrice() {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
            NumberFormat.currency(locale: 'eu', symbol: '').format(double.parse(widget.currencyPrice)),
            style: TextStyle(
                fontSize: widget.styles.currencyPriceFontSize(),
                color: color
            )
        ),
        if(widget.percent != null)
          Container(
          height: 30,
          alignment: Alignment.centerRight,
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                color: double.parse(widget.percent!) > 0 ? Colors.green : Colors.red
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                widget.percent! + ' %',
              ),
            )
        ),
      ],
    );
  }
}
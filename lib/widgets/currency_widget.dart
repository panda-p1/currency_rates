import 'dart:async';
import 'dart:math';

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
  final String? oldPrice;
  final Function? onDeleteIconPress;
  final String? percent;

  final Function? onGraphicPressed;
  final List<GraphicPrice> chartData;

  CurrencyWidget({Key? key,
    this.oldPrice, required this.onGraphicPressed,
    this.deleteIcon, this.onDeleteIconPress,
    this.currencyName, this.percent,
    required this.currencyPrice, required this.chartData,
    required this.styles}) : super(key: key);
  @override
  State<CurrencyWidget> createState() => _CurrencyWidgetState();
}
class _CurrencyWidgetState extends State<CurrencyWidget> with TickerProviderStateMixin {

  double? prevYmax;
  double? prevYmin;
  late Timer _timer;
  late Timer _reloadTimer;
  Color? color;
  String? previousPrice;
  bool animate = false;
  List<GraphicPrice> dashedLine = [];
  //Initialize the data source
  @override
  void initState() {
    if(widget.chartData.isNotEmpty) {
      prevYmin = double.parse(widget.oldPrice!)
          - (widget.chartData.map((data) => double.parse(data.price)).toList().reduce(max)
              - double.parse(widget.oldPrice!)
          ).abs();
      prevYmax = double.parse(widget.oldPrice!)
          + (widget.chartData.map((data) => double.parse(data.price)).toList().reduce(max)
              -double.parse(widget.oldPrice!)
          ).abs();
    }

    _timer = Timer(Duration(milliseconds: 400), () {
      _timer.cancel();
    });
    _reloadTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      dashedLine = [];
      for(var i = 0; i < 21; i++) {
        dashedLine.add(GraphicPrice(time: DateTime.now().subtract(Duration(seconds: 10 * i)), open: widget.oldPrice!, close: widget.oldPrice!));
      }
      // chartData.add(GraphicPrice(time: DateTime.now(), open: widget.currencyPrice, close: widget.currencyPrice));
      dashedLine = [];
      for(var i = 0; i < 21; i++) {
        dashedLine.add(GraphicPrice(time: DateTime.now().subtract(Duration(seconds: 10 * i)), open: widget.oldPrice!, close: widget.oldPrice!));
      }
      // if(chartData.length == 70) {
      //   chartData.removeAt(0);
      // }
      if(widget.chartData.isNotEmpty) {
        final yMax = double.parse(widget.oldPrice!) + (double.parse(widget.currencyPrice) - double.parse(widget.oldPrice!)).abs();
        final yMin = double.parse(widget.oldPrice!) - (double.parse(widget.currencyPrice) - double.parse(widget.oldPrice!)).abs();
        if(prevYmax! < yMax) {
          prevYmax = yMax;
        }
        if(prevYmin! > yMin) {
          prevYmin = yMin;
        }
        setState(() {});
      }

    });
    for(var i = 0; i < 21; i++) {
      dashedLine.add(GraphicPrice(time: DateTime.now().subtract(Duration(seconds: 10 * i)), open: widget.oldPrice!, close: widget.oldPrice!));
    }
    // chartData.add(GraphicPrice(time: DateTime.now(), open: widget.currencyPrice, close: widget.currencyPrice));

    super.initState();
  }

  Widget _buildLiveLineChart() {
    return Center(
      child: SizedBox(
        height: widget.styles.currencyWidgetHeight() + 1,
        width: 100,
          child: Center(
            child: SfCartesianChart(
              onChartTouchInteractionUp: (d) {
                widget.onGraphicPressed!();
              },
              plotAreaBorderWidth: 0,
              primaryXAxis: DateTimeAxis(
                  maximum: DateTime.now() ,
                  minimum: DateTime.now().subtract(Duration(minutes: 1)),
                  isVisible: false
              ),
              primaryYAxis: NumericAxis(
                  maximum: prevYmax! + prevYmax! * 0.000001,
                  minimum: prevYmin! - prevYmin! * 0.000001,
                  isVisible: false,
              ),
              series: <LineSeries<GraphicPrice, DateTime>>[
                LineSeries<GraphicPrice, DateTime>(
                  dataSource: dashedLine,
                  dashArray: <double>[3.5,3.5],
                  color: double.parse(widget.percent!) > 0 ? Colors.green : Colors.red,
                  xValueMapper: (GraphicPrice sales, _) => sales.time,
                  yValueMapper: (GraphicPrice sales, _) => double.parse(sales.price),
                    animationDuration: 0

                ),
                LineSeries<GraphicPrice, DateTime>(
                  dataSource: widget.chartData,
                  color: double.parse(widget.percent!) > 0 ? Colors.green : Colors.red,
                  xValueMapper: (GraphicPrice sales, _) => sales.time,
                  yValueMapper: (GraphicPrice sales, _) => double.parse(sales.price),
                  animationDuration: 0
                ),

              ]),
          ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _reloadTimer.cancel();
    super.dispose();
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
      height: widget.styles.currencyWidgetHeight() + 5,

      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 14.0, right: MediaQuery.of(context).orientation == Orientation.portrait ? 14 : 36),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _currencyName(),
                Spacer(),
                if(widget.chartData.isNotEmpty) _buildLiveLineChart(),
                _currencyPrice(),
              ],
            ),
          ),
          // _buildLiveLineChart(),
          // Divider(),
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
      // if(widget.deleteIcon != null && widget.deleteIcon!)
      //   Positioned(
      //       right: -20,
      //       top: -15,
      //       child: IconButton(
      //         icon: Icon(Icons.remove_circle_sharp, color: Colors.red, size: 30),
      //         onPressed: () => widget.onDeleteIconPress!(),))
    ],
    );
  }
  Widget _currencyPrice() {

    return SizedBox(
      width: widget.styles.currencyPriceWidth(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
              NumberFormat.currency(locale: 'eu', symbol: '').format(double.parse(widget.currencyPrice)),
              style: TextStyle(
                  fontSize: widget.styles.currencyPriceFontSize(),
                  color: color
              ),
              overflow: TextOverflow.ellipsis,
          ),
          if(widget.percent != null)
            Row(
              children: [
                Spacer(),
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
            )
        ],
      ),
    );
  }
}
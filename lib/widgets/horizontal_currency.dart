import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HorizontalCurrencyWidget extends StatefulWidget {
  final String currencyPrice;
  final String currencyName;
  const HorizontalCurrencyWidget({Key? key,
    required this.currencyPrice,
    required this.currencyName,
  }) : super(key: key);

  @override
  _HorizontalCurrencyState createState() => _HorizontalCurrencyState();
}

class _HorizontalCurrencyState extends State<HorizontalCurrencyWidget> {
  late Timer _timer;
  Color? color;
  String? previousPrice;
  bool animate = false;
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
        color = Colors.blue;
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _currencyName(),
        Spacer(),
        _currencyPrice(),
      ],
    );
  }
  Widget _currencyName() {
    return Text(
      widget.currencyName,
      style: TextStyle(fontSize: 30),
    );
  }
  Widget _currencyPrice() {
    return Text(
        NumberFormat.currency(locale: 'eu', symbol: '').format(double.parse(widget.currencyPrice)),
        style: TextStyle(
            color: color,
            fontSize: 30
        )
    );
  }
}

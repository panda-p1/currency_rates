import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../styles.dart';

class CurrencyWidget extends StatefulWidget {
  final String? currencyName;
  final String currencyPrice;
  final CurrencyStyles styles;
  final bool? deleteIcon;
  final Function? onDeleteIconPress;
  CurrencyWidget({Key? key,
    this.deleteIcon, this.onDeleteIconPress,
    this.currencyName,
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
    return SizedBox(
      height: widget.styles.currencyWidgetHeight(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _currencyName(),
          _currencyPrice(),
        ],
      ),
    );
  }



  Widget _currencyName() {
    if(widget.currencyName == null) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Stack(
        clipBehavior: Clip.none, children: [
        Text(
          widget.currencyName!,
          style: TextStyle(
              fontSize: widget.styles.currencyNameFontSize(),
              color: widget.styles.currencyNameFontColor()),),
        if(widget.deleteIcon != null && widget.deleteIcon!)
          Positioned(
              right: -20,
              top: -15,
              child: IconButton(
                icon: Icon(Icons.remove_circle_sharp, color: Colors.red, size: 30),
                onPressed: () => widget.onDeleteIconPress!(),))
      ],
      ),
    );
  }
  Widget _currencyPrice() {
    return Text(
        NumberFormat.currency(locale: 'eu', symbol: '').format(double.parse(widget.currencyPrice)),
        style: TextStyle(
            fontSize: widget.styles.currencyPriceFontSize(),
            color: color
        )
    );
  }
}
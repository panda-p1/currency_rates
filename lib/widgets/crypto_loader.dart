import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../styles.dart';

class CryptoLoader extends StatefulWidget {
  final CurrencyStyles styles;
  const CryptoLoader({Key? key, required this.styles}) : super(key: key);

  @override
  _CryptoLoaderState createState() => _CryptoLoaderState();
}

class _CryptoLoaderState extends State<CryptoLoader> {
  String dots = '.';
  late Timer _timer;

  @override
  void initState() {
    _timer = Timer.periodic(const Duration(milliseconds: 300), (t) {
      setState(() {
        dots = dots.length == 3 ? '.' : dots + '.';
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.styles.currencyWidgetHeight(),
      child: Center(child: Text('Loading ' + dots, style: TextStyle(fontSize: widget.styles.currencyNameFontSize()),),),
    );
  }
  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}
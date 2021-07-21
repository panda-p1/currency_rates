import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../styles.dart';

class CryptoLoader extends StatefulWidget {
  final CurrencyStyles styles;
  final bool isEditingMode;
  final Function onDeletePress;
  final String cryptoName;
  final int index;
  const CryptoLoader({Key? key, required this.index,
    required this.onDeletePress, required this.styles,
    required this.cryptoName, required this.isEditingMode}) : super(key: key);

  @override
  _CryptoLoaderState createState() => _CryptoLoaderState();
}

class _CryptoLoaderState extends State<CryptoLoader> {

  @override
  Widget build(BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
        if(widget.isEditingMode)
          IconButton(
              padding: EdgeInsets.only(left: 8),
              constraints: BoxConstraints(),
              splashRadius: 5,
              onPressed: () => widget.onDeletePress(widget.cryptoName),
              icon: Icon(Icons.remove_circle_sharp, color: Colors.red,)),

        Padding(
          padding: EdgeInsets.only(left: 14.0),
          child: Text(widget.cryptoName,
              style: TextStyle(
                fontSize: widget.styles.currencyNameFontSize(),
                color: widget.styles.currencyNameFontColor()
              )
          ),
        ),
        Spacer(),
        Padding(
          padding: EdgeInsets.only(right: MediaQuery.of(context).orientation == Orientation.portrait ? 14 : 36),
          child:           Loader(styles: widget.styles,),
          // child: widget.isEditingMode
          //     ?
          // ReorderableDragStartListener(
          //   // index: orderListener.value.keys.toList().indexOf(crypto.name),
          //     index: widget.index,
          //     child: IconButton(
          //         splashRadius: 20,
          //         onPressed: () {},
          //         icon: Icon(Icons.format_align_justify_outlined )
          //     )
          // )
          //     :
          //     Container()
          // ,
        ),
          if(widget.isEditingMode)
            ReorderableDragStartListener(
              // index: orderListener.value.keys.toList().indexOf(crypto.name),
                index: widget.index,
                child: IconButton(
                    splashRadius: 20,
                    onPressed: () {},
                    icon: Icon(Icons.format_align_justify_outlined )
                )
            )
      ],

    );
  }

}

class Loader extends StatefulWidget {
  final CurrencyStyles styles;

  const Loader({Key? key, required this.styles}) : super(key: key);

  @override
  _LoaderState createState() => _LoaderState();
}

class _LoaderState extends State<Loader> {
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

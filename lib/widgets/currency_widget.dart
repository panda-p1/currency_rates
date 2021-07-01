import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../styles.dart';

class CurrencyWidget extends StatefulWidget {
  final String currencyName;
  final String currencyPrice;
  final Grad_Direction? gradDirection;
  final CurrencyStyles styles;
  final Color? initColor;
  final Color finalColor;
  final bool animated;
  final bool? deleteIcon;
  final Function? onDeleteIconPress;
  CurrencyWidget({Key? key,
    this.deleteIcon, this.onDeleteIconPress,
    required this.finalColor,
    required this.animated, required this.currencyName,
    required this.currencyPrice, this.gradDirection,
    required this.styles, this.initColor}) : super(key: key);
  @override
  State<CurrencyWidget> createState() => _CurrencyWidgetState();
}
class _CurrencyWidgetState extends State<CurrencyWidget> with TickerProviderStateMixin {
  late Animation<Color?> animationColor;
  AnimationController? controller;

  @override
  void initState() {
    if(widget.animated) {
      controller = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 2000),);

      animationColor = ColorTween(begin: widget.initColor, end: widget.finalColor)
          .animate(controller!);
    }

    super.initState();
  }
  @override
  void dispose() {
    if(controller != null) {
      controller!.dispose();
    }
    super.dispose();
  }
  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(widget.animated) {
      this.updateAnimation();
    }
  }

  void updateAnimation() {
    setState(() {
      animationColor = ColorTween(begin: widget.initColor, end: widget.finalColor)
          .animate(controller!);
    });

    if(controller!.status == AnimationStatus.completed || controller!.status == AnimationStatus.dismissed ||
        controller!.status == AnimationStatus.forward
    ) {
      controller!.value = 0;
      controller!.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.styles.currencyWidgetHeight(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _currencyName()
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  widget.currencyPrice.toString(),
                  style: TextStyle(
                      color: widget.finalColor,
                      fontSize: widget.styles.currencyPriceFontSize())),
              // Text(
              //     widget.currencyPrice.toString(),
              //     style: TextStyle(
              //         color: widget.finalColor,
              //         fontSize: widget.styles.currencyPriceFontSize())),
              if(widget.gradDirection != null)
                widget.gradDirection == Grad_Direction.down
                    ? Icon(Icons.arrow_drop_down_outlined, size: widget.styles.iconsSize(),)
                    : Icon(Icons.arrow_drop_up_outlined, size: widget.styles.iconsSize(),)
            ],
          ),
        ],
      ),
    );
  }

  Widget _currencyName() {
    return Stack(
      clipBehavior: Clip.none, children: [
      Text(
        widget.currencyName,
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
    );
  }
}
import 'dart:async';
import 'dart:math';
import 'dart:io' as io;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:currencies_pages/bloc/currency/bloc.dart';
import 'package:currencies_pages/bloc/currency/events.dart';
import 'package:currencies_pages/bloc/currency/states.dart';
import 'package:currencies_pages/bloc/localData/bloc.dart';
import 'package:currencies_pages/bloc/localData/events.dart';
import 'package:currencies_pages/model/currencies.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

import '../styles.dart';
import 'config_screen.dart';

double degToRad(double deg) => deg * (pi / 180.0);


enum Statuses {
  unknown,
  online,
  offline
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}
const double _heightForSignal = 100;
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late String succeedTime = '';
  Statuses lastStatus = Statuses.online;
  double _signalHeight = _heightForSignal;
  bool topLoading = false;

  double yScrollPosition = 0;
  bool dropped = false;

  double topLoaderHeight = 0.001;
  int carouselPageIndex = 0;
  late Currencies? currencies;
  Tween<double> _rotationTween = Tween(begin: 360, end: 0);
  late Animation<double> animation;
  late Animation<Color?> animation1;
  late AnimationController controller;
  ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    _loadRates();
    _scrollController.addListener(() {
      if(_scrollController.position.pixels <= 0 && !dropped) {
        yScrollPosition = - _scrollController.position.pixels;
      }

    });
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 5000),);

    animation =
      _rotationTween.animate(controller)
        ..addStatusListener((status) {
          if (status == AnimationStatus.dismissed) {
            controller.reset();
          }
          if (status == AnimationStatus.completed) {
            context.read<CurrenciesBloc>().add(CurrenciesEvents.getRate);
          }

        });
    animation1 = ColorTween(begin: Colors.green, end: Colors.grey[700])
          .animate(controller);
    super.initState();
  }

  _loadRates() {
    context.read<CurrenciesBloc>().add(CurrenciesEvents.getRate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Rates"),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.settings,
              ),
              onPressed: () async {
                final delay1 = await Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    BlocProvider.value(
                      value: BlocProvider.of<LocalDataBloc>(context),
                      child: ConfigScreen(),
                    )));
                context.read<CurrenciesBloc>().add(CurrenciesEvents.getRate);
                controller.duration = Duration(milliseconds: (delay1 * 1000).toInt());
                controller.value = 0;
                controller.forward();
              },
            )
          ],),
        body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (d) {
              if(topLoaderHeight + d.delta.dy > 0) {
                setState(() {
                  topLoaderHeight += d.delta.dy;
                });
              }
            },
            onVerticalDragEnd: (d) {
              if(topLoaderHeight > _signalHeight) {
                setState(() {
                  topLoading = true;
                });
                Future.delayed(Duration(seconds: 1), () async {
                  context.read<CurrenciesBloc>().add(CurrenciesEvents.getRate);
                });
                controller.stop();
              }
              setState(() {
                topLoaderHeight = 0;
              });
            },
            child: _body()),
        // persistentFooterButtons: [RaisedButton(onPressed: () {controller.stop();})],
    );
  }

  Widget _body() {
    return OrientationBuilder(builder: (_,orientation) {
      orientation == Orientation.landscape ? _signalHeight = _heightForSignal / 2 : _signalHeight = _heightForSignal;
      return Padding(
        padding: orientation == Orientation.landscape ? const EdgeInsets.only(right: 16.0) : EdgeInsets.zero,
        child: Column(
          children: [
            topLoading
                ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(),
                )
                : SizedBox(height: topLoaderHeight,),
            Expanded(
              child: BlocBuilder<CurrenciesBloc, CurrenciesState>(builder: (BuildContext context, CurrenciesState state) {
                if(state is CurrenciesLoaded) {
                  context.read<LocalDataBloc>().add(StoreCurrencies(currencies: state.currencies));
                  controller.duration = Duration(milliseconds: (state.currencies.delay * 1000).toInt());
                  if(controller.status == AnimationStatus.dismissed) {
                    controller.forward();
                  }
                  if(controller.status == AnimationStatus.completed) {
                    Future.delayed(Duration.zero, () async {
                      controller.value = 0;
                      controller.forward();
                    });
                  }
                  return _bodyUI(state.currencies, Statuses.online, orientation, context);
                }
                if(state is LocalCurrenciesLoaded) {
                  Timer(const Duration(seconds: 2), () {
                    context.read<CurrenciesBloc>().add(CurrenciesEvents.getRate);
                  });
                  controller.duration = Duration(milliseconds: (state.currencies.delay * 1000).toInt());
                  return _bodyUI(state.currencies, Statuses.online, orientation, context);
                }
                return Container();
              }, buildWhen: (state1, state2) {
                return !(state1 is LocalCurrenciesLoaded && state2 is LocalCurrenciesLoaded)  && state2 is! CurrenciesLoading;
              }),
            ),
      BlocBuilder<CurrenciesBloc, CurrenciesState>(builder: (BuildContext context, CurrenciesState state) {
            print(state);
            if(state is CurrenciesLoaded) {
              succeedTime = state.currencies.time;
              return _footerUI(status: Statuses.online);
            }
            if(state is LocalCurrenciesLoaded) {
              succeedTime = state.currencies.time;
              return _footerUI(status: Statuses.offline);
            }
            if(state is CurrenciesLoading) {
              return _footerUI(status: Statuses.unknown);
            }
            return Container();
            })
          ],
        ),
      );
    });
  }

  Widget _bodyUI(Currencies currencies, Statuses status, Orientation orientation, BuildContext context) {
    final styles = orientation == Orientation.portrait ? PortraitStyles() : LandscapeStyles();
    final f = intl.NumberFormat();
    final items = [
      CurrencyWidget(currencyName: 'Доллар',
        currencyPrice: f.format(currencies.usd),
        gradDirection: currencies.usdChange,
        styles: styles,
      ),
      CurrencyWidget(currencyName: 'Евро',
        currencyPrice: f.format(currencies.eur),
        gradDirection: currencies.eurChange,
        styles: styles,
      ),
      CurrencyWidget(currencyName: 'Нефть Brent',
        currencyPrice: f.format(currencies.brent),
        gradDirection: currencies.brentChange,
        styles: styles,
      ),
      CurrencyWidget(currencyName: 'Евро/Доллар',
        currencyPrice: f.format(currencies.eurusd),
        gradDirection: currencies.eurusdChange,
        styles: styles,
      ),
      CurrencyWidget(currencyName: 'Биткоин/Рубль',
        currencyPrice: f.format(currencies.btc),
        gradDirection: currencies.btcChange,
        styles: styles,
      ),
      CurrencyWidget(currencyName: 'Биткоин/Доллар',
        currencyPrice: f.format(currencies.btcusd),
        gradDirection: currencies.btcusdChange,
        styles: styles,
      ),
      if(io.Platform.isAndroid)
      CurrencyWidget(currencyName: 'Биткоин/Доллар',
        currencyPrice: f.format(currencies.btcusd),
        gradDirection: currencies.btcusdChange,
        styles: styles,
      ),
      if(io.Platform.isAndroid)
        CurrencyWidget(currencyName: 'Биткоин/Доллар',
        currencyPrice: f.format(currencies.btcusd),
        gradDirection: currencies.btcusdChange,
        styles: styles,
      ),
    ];
    if(topLoading) {
      Future.delayed(Duration(seconds: 1), () async {
        setState(() {
          topLoading = false;
        });
        controller.reset();
      });
    }
    if(orientation == Orientation.portrait) {
      return _portraitUI(currencies: currencies, items: items);
    }
    if(orientation == Orientation.landscape) {
      return _landscapeUI(currencies: currencies, context: context, items: items);
    }
    return Container();
  }
  Widget _landscapeUI({required Currencies currencies, required BuildContext context, required List<Widget> items}) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: CarouselSlider(
          items: items,
          options: CarouselOptions(initialPage: carouselPageIndex, onPageChanged: (idx, _) {carouselPageIndex = idx;})),
    );
  }
  Widget _portraitUI({required Currencies currencies, required List<Widget> items}) {
    return NotificationListener(

      onNotification: (scrollNotification) {
        if(scrollNotification is ScrollEndNotification) {
          dropped = false;
        }
        if(scrollNotification is ScrollUpdateNotification) {
          if(scrollNotification.dragDetails == null) {
            if(_scrollController.position.pixels < 0 && scrollNotification.scrollDelta! > 0) {
              dropped = true;
            }
            if(yScrollPosition > _signalHeight) {
              yScrollPosition = 0;
              setState(() {
                topLoading = true;
              });
              Future.delayed(Duration(seconds: 1), () async {
                context.read<CurrenciesBloc>().add(CurrenciesEvents.getRate);
              });
              controller.stop();
            }
          }
        }
        return false;
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: BouncingScrollPhysics(),
        child: Column(
          children: items,
        ),
      ),
    );
  }

  Widget _footerUI({required Statuses status}) {
    final Statuses status1;
    if(status == Statuses.offline || status == Statuses.online) {
      lastStatus = status;
      status1 = status;
    } else {
      status1 = lastStatus;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child:Text(succeedTime, style: TextStyle(fontSize: SucceedDatetime.fontSize)),
        ),

        Spacer(),

        AnimatedBuilder(
          animation: animation,
          builder: (_,snapshot) {
            return Padding(
              padding: const EdgeInsets.only(right: 16.0, bottom: 12),
              child: CustomPaint(
                painter: status1 != Statuses.offline
                    ? Painter(sweepAngle: animation.value, color: animation1.value == null ? Colors.green : animation1.value!, status: status1)
                    : Painter(sweepAngle: degToRad(20670), color: Colors.red, status: status1),
                size: Size(RingStyles.ringSize,RingStyles.ringSize),
              ),
            );
          },
        ),
      ],
    );
  }

}

class Painter extends CustomPainter {

  final double sweepAngle;
  final Color color;
  final Statuses status;
  Painter({required this.sweepAngle, required this.color, required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..strokeWidth = RingStyles.ringWidth   // 1.
      ..style = PaintingStyle.stroke   // 2.
      ..color = color;   // 3.

    final textStyle = TextStyle(
      color: color,
      fontSize: RingStyles.ringPercentTextSize,
    );
    final textStyle1 = TextStyle(
      color: Colors.grey,
      fontSize: RingStyles.ringStatusTextSize,
    );
    final textSpan = TextSpan(
      // text: (sweepAngle/3.6).floor().toString(),
      style: textStyle,
    );
    final textSpan1 = TextSpan(
      // text: status.toString().substring(status.toString().indexOf('.') + 1),
      style: textStyle1,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    final textPainter1 = TextPainter(
      text: textSpan1,
      textDirection: TextDirection.ltr,
    );
    textPainter1.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );

    final xCenter = (size.width - textPainter.width) / 2;
    final yCenter = (size.height - textPainter.height) / 2 - 4;
    final x1Center = (size.width - textPainter1.width) / 2;
    final y1Center = (size.height - textPainter1.height) / 2;
    final offset = Offset(xCenter, yCenter);
    final offset1 = Offset(x1Center, y1Center + 7);
    textPainter.paint(canvas, offset);
    textPainter1.paint(canvas, offset1);

    final Paint paint1 = Paint()
      ..strokeWidth = RingStyles.ringWidth   // 1.
      ..style = PaintingStyle.stroke   // 2.
      ..color = status == Statuses.offline ? Colors.red : RingStyles.backgroundRingColor;
    final path1 = Path()
      ..arcTo(   // 4.
          Rect.fromCenter(
            center: Offset(size.height / 2, size.width / 2),
            height: size.height,
            width: size.width,
          ),   // 5.
          0,
          2*pi- 0.001, // 7.
          false);

    final path = Path()
      ..arcTo(   // 4.
          Rect.fromCenter(
            center: Offset(size.height / 2, size.width / 2),
            height: size.height,
            width: size.width,
          ),   // 5.
          degToRad(180),   // 6.
          degToRad(sweepAngle), // 7.
          false);
    if(status != Statuses.offline) {

    }
    canvas.drawPath(path1, paint1);   // 8.

    canvas.drawPath(path, paint);   // 8.
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // bad, but okay for example
    return true;
  }
}

class CurrencyWidget extends StatelessWidget {
  final String currencyName;
  final String currencyPrice;
  final Grad_Direction gradDirection;
  final CurrencyStyles styles;
  const CurrencyWidget({Key? key,
    required this.currencyName, required this.currencyPrice,
    required this.gradDirection, required this.styles}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(currencyName, style: TextStyle(fontSize: styles.currencyNameFontSize(), color: styles.currencyNameFontColor()),),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(currencyPrice.toString(), style: TextStyle(fontSize: styles.currencyPriceFontSize()),),
              gradDirection == Grad_Direction.down
                  ? Icon(Icons.arrow_drop_down_outlined, size: styles.iconsSize(),)
                  : Icon(Icons.arrow_drop_up_outlined, size: styles.iconsSize(),)
            ],
          )
        ],
      ),
    );
  }
}

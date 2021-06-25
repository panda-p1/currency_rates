import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:currencies_pages/bloc/crypto/bloc.dart';
import 'package:currencies_pages/bloc/crypto/events.dart';
import 'package:currencies_pages/bloc/crypto/states.dart';
import 'package:currencies_pages/bloc/currency/bloc.dart';
import 'package:currencies_pages/bloc/currency/events.dart';
import 'package:currencies_pages/bloc/currency/states.dart';
import 'package:currencies_pages/bloc/localData/bloc.dart';
import 'package:currencies_pages/bloc/localData/events.dart';
import 'package:currencies_pages/model/currencies.dart';
import 'package:currencies_pages/model/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

import '../styles.dart';
import 'config_screen.dart';

double degToRad(double deg) => deg * (pi / 180.0);

enum Price_Changes {
  equal,
  increased,
  decreased
}

enum Statuses {
  unknown,
  online,
  offline
}

Map<Currency_Type, String> currencyTypeMapper = {
  // Currency_Type.btc: 'Биткоин',
  Currency_Type.eurusd: 'Евро/Доллар',
  Currency_Type.eur: 'Евро',
  Currency_Type.brent: 'Нефть Brent',
  Currency_Type.usd: 'Доллар',
  // Currency_Type.btcusd: 'Биткоин/Доллар',
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

const double _heightForSignal = 100;

// WebSocketChannel dogeChannel = WebSocketChannel.connect(
//   Uri.parse('wss://stream.binance.com:9443/stream?streams=dogeusdt@bookTicker'),
// );

class StreamWidgetBuilder {
  Widget? widget;
  void init() {
    widget = Container();
  }
  void addStreamBuilder() {

  }
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {

  List<StreamController> cryptoControllers = [];

  Map<Currency_Type, num> previousCurrencies = {};
  late String succeedTime = '';
  Statuses lastStatus = Statuses.online;
  double _signalHeight = _heightForSignal;
  bool topLoading = false;

  double yScrollPosition = 0;
  bool dropped = false;

  final ValueNotifier<double> _topLoaderHeight = ValueNotifier<double>(0);
  final ValueNotifier<int> landscapePageIndex = ValueNotifier<int>(0);
  final ValueNotifier<int> portraitPageIndex = ValueNotifier<int>(0);

  CarouselController landscapeCarouselController = CarouselController();
  CarouselController portraitCarouselController = CarouselController();
  late Currencies? currencies;
  Tween<double> _rotationTween = Tween(begin: 360, end: 0);
  late Animation<double> animation;
  late Animation<Color?> animation1;
  late AnimationController controller;
  ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    _loadRates();
    _initCryptoWebSocket();
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

  _initCryptoWebSocket() {
    context.read<CryptoBloc>().add(CryptoInitConnection());
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
                    )
                ));
                context.read<CurrenciesBloc>().add(CurrenciesEvents.getRate);
                controller.duration = Duration(milliseconds: (delay1 * 1000).toInt());
                controller.value = 0;
                // controller.forward();
              },
            )
          ],
        ),
        body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
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
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: CircularProgressIndicator(),
                )
                : ValueListenableBuilder<double>(
                    builder: (context, double value, child) {
                      return SizedBox(height: value);
                    }, valueListenable: _topLoaderHeight,
                  ),
            Expanded(
              child: BlocBuilder<CurrenciesBloc, CurrenciesState>(builder: (BuildContext context, CurrenciesState state) {
                if(state is CurrenciesLoaded) {
                  context.read<LocalDataBloc>().add(StoreCurrencies(currencies: state.currencies));
                  controller.duration = Duration(milliseconds: (state.currencies.delay * 1000).toInt());
                  if(controller.status == AnimationStatus.dismissed) {
                    // controller.forward();
                  }
                  if(controller.status == AnimationStatus.completed) {
                    Future.delayed(Duration.zero, () async {
                      controller.value = 0;
                      // controller.forward();
                    });
                  }
                  return _bodyUI(state.currencies, Statuses.online, orientation, context);
                }
                if(state is LocalCurrenciesLoaded) {
                  Timer(const Duration(seconds: 2), () {
                    _loadRates();
                    context.read<CryptoBloc>().add(RetryConnection());
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
    Color initColor = Theme.of(context).accentColor;
    final items = currencies.arrayOfCurrencies.asMap().entries.map((entry) {
      final currency = entry.value;

      if(entry.key == 0) {
        return BlocBuilder<CryptoBloc, CryptoState>(builder: (BuildContext context, CryptoState state) {
          if(state is CryptoError) {
            return Container();
          }
          if(state is LocalCryptoLoaded) {
            return _localCryptoLoaded(state.cryptoList, orientation);
          }
          if(state is CryptoLoaded) {
            return _cryptoLoaded(state.cryptoInfo, orientation);
          }
          return Container();
        });
      }
      if(previousCurrencies.isNotEmpty) {
        if(currency.price < previousCurrencies[currency.type]!) {
          initColor = Colors.red;
        }
        if(currency.price > previousCurrencies[currency.type]!) {
          initColor = Colors.blue;
        }
      }
      return CurrencyWidget(
        animated: true,
        finalColor: Theme.of(context).accentColor,
        initColor: initColor,
        currencyName: currencyTypeMapper[currency.type]!,
        currencyPrice: f.format(currency.price),
        gradDirection: currency.gradDirection,
        styles: styles,
      );
    }).toList();

    previousCurrencies = currencies.getCurrenciesAndTheirRates();

    if(topLoading) {
      Future.delayed(Duration(seconds: 1), () async {
        setState(() {
          topLoading = false;
        });
        controller.reset();
      });
    }

    if(orientation == Orientation.portrait) {
      return _notifListener(child: _portraitUI(currencies: currencies, items: items));
    }
    if(orientation == Orientation.landscape) {
      return _landscapeUI(currencies: currencies, context: context, items: items);
    }
    return Container();
  }

  Widget _landscapeUI({required Currencies currencies, required BuildContext context, required List<Widget> items}) {
    return  ValueListenableBuilder<int>(
      builder: (_, int value, __) {
        return Column(children: [
          Expanded(
            child: SizedBox(
              width:MediaQuery.of(context).size.width,
              child: CarouselSlider(
                items: items.map((e) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: e,
                    ),
                  );
                }).toList(),
                carouselController: landscapeCarouselController,
                options: CarouselOptions(
                    aspectRatio: 2.0,
                    onPageChanged: (index, reason) {
                      landscapePageIndex.value = index;
                    }),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => landscapeCarouselController.animateToPage(entry.key),
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black)
                          .withOpacity(landscapePageIndex.value == entry.key ? 0.9 : 0.4)),
                ),
              );
            }).toList(),
          ),
        ]);
      },
      valueListenable: landscapePageIndex,
    );
    // return _landscapeCarousel(items.map((e) {
    //       return e;
    //     }).toList());
  }
  Widget _portraitUI({required Currencies currencies, required List<Widget> items}) {
    return Column(
      children: items,
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
    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
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
              builder: (_, snapshot) {
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
        ),
      ),
    );
  }

  Widget _portraitCarousel(List<Widget> items) {
    return ValueListenableBuilder<int>(
      builder: (_, int value, __) {
        return Column(children: [
          SizedBox(
            width:MediaQuery.of(context).size.width,
            child: CarouselSlider(
              items: items,
              carouselController: portraitCarouselController,
              options: CarouselOptions(
                  aspectRatio: 2.0,
                  onPageChanged: (index, reason) {
                    portraitPageIndex.value = index;
                  }),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () => portraitCarouselController.animateToPage(entry.key),
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black)
                          .withOpacity(portraitPageIndex.value == entry.key ? 0.9 : 0.4)),
                ),
              );
            }).toList(),
          ),
        ]);
      },
      valueListenable: portraitPageIndex,
    );
  }

  Widget _cryptoLoaded(cryptoInfo, Orientation orientation) {
    if(cryptoControllers.isEmpty) {
      cryptoControllers = cryptoInfo;
    }

    final items = cryptoInfo.map<Widget>((controller) {
      return StreamBuilder(
          stream: controller.stream,
          builder: (_, snapshot1)
          {
            if (!snapshot1.hasData) {
              return Container();
            }
            final crypto = jsonDecode(snapshot1.data!.toString())['data'];
            final price = ((double.parse(crypto['b']) + double.parse(crypto['a'])) / 2).toString();
            context.read<LocalDataBloc>().add(StoreCrypto(crypto: Crypto(
              name: crypto['s'], price: price,
            )));

            return CurrencyWidget(
              currencyName: crypto['s'],
              styles: orientation == Orientation.portrait ? PortraitStyles() : LandscapeStyles(),
              currencyPrice: price.length > 9 ? price.substring(0, 9) : price,
              animated: false,
              finalColor: Theme.of(context).accentColor,
            );
          });
    }).toList();
    print(items);
    if(orientation == Orientation.portrait) {
      return _portraitCarousel(items);
    }
    if(orientation == Orientation.landscape) {
      return Column(
        children: items,
      );
    }
    return Container();
  }
  Widget _localCryptoLoaded(List<Crypto> cryptoList, Orientation orientation) {
    final items = cryptoList.map((crypto) {
      return CurrencyWidget(
          finalColor: Theme.of(context).accentColor,
          animated: false,
          currencyName: crypto.name,
          currencyPrice: crypto.price,
          styles: orientation == Orientation.portrait ? PortraitStyles() : LandscapeStyles());
    }).toList();
    if(orientation == Orientation.portrait) {
      return _portraitCarousel(items);
    }
    if(orientation == Orientation.landscape) {
      return Column(
        children: items,
      );
    }
    return Container();
  }

  NotificationListener _notifListener({required Widget child}) {
    return NotificationListener(
      onNotification: _onScroll,
      child: SingleChildScrollView(
          controller: _scrollController,
          physics: BouncingScrollPhysics(),
          child: child
      ),
    );
  }
  bool _onScroll(scrollNotification) {
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
  }
  void _onVerticalDragUpdate(DragUpdateDetails d) {
    if(_topLoaderHeight.value + d.delta.dy > 0) {
      _topLoaderHeight.value += d.delta.dy;
    }
  }
  void _onVerticalDragEnd(DragEndDetails d) {
    if(_topLoaderHeight.value > _signalHeight) {
      setState(() {
        topLoading = true;
      });
      Future.delayed(Duration(seconds: 1), () async {
        context.read<CurrenciesBloc>().add(CurrenciesEvents.getRate);
      });
      controller.stop();
    }
    _topLoaderHeight.value = 0;
  }
  @override
  void dispose() {
    cryptoControllers.forEach((element) {
      element.close();
    });
    super.dispose();

  }
}

String _getCryptoPrice(Map cryptoInfo) {
  final price = ((double.parse(cryptoInfo['data']['b']) + double.parse(cryptoInfo['data']['a']))/2).toStringAsFixed(5);
  return price.length > 7 ? price.substring(0, 9) : price;
}

Widget _cryptoLoader(String cryptoName, styles) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Text(cryptoName, style: TextStyle(fontSize: styles.currencyPriceFontSize()),),
      ),
      CircularProgressIndicator()
    ],
  );
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

class CurrencyWidget extends StatefulWidget {
  final String currencyName;
  final String currencyPrice;
  final Grad_Direction? gradDirection;
  final CurrencyStyles styles;
  final Color? initColor;
  final Color finalColor;
  final bool animated;
  CurrencyWidget({Key? key,
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
    final currencyPrice;
    if(widget.animated) {
      currencyPrice = AnimatedBuilder(
          animation: animationColor,
          builder: (_, snapshot) {
            return Text(
                widget.currencyPrice.toString(),
                style: TextStyle(
                    color: animationColor.value,
                    fontSize: widget.styles.currencyPriceFontSize()));
          });
    } else {
      currencyPrice = Text(
          widget.currencyPrice.toString(),
          style: TextStyle(
              color: widget.finalColor,
              fontSize: widget.styles.currencyPriceFontSize()));
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(widget.currencyName, style: TextStyle(fontSize: widget.styles.currencyNameFontSize(), color: widget.styles.currencyNameFontColor()),),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            currencyPrice,
            if(widget.gradDirection != null)
            widget.gradDirection == Grad_Direction.down
                ? Icon(Icons.arrow_drop_down_outlined, size: widget.styles.iconsSize(),)
                : Icon(Icons.arrow_drop_up_outlined, size: widget.styles.iconsSize(),)
          ],
        ),
      ],
    );
  }

}
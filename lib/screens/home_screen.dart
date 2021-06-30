import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:reorderables/reorderables.dart';
import 'package:currencies_pages/api/localData.dart';
import 'package:currencies_pages/bloc/crypto/bloc.dart';
import 'package:currencies_pages/bloc/crypto/events.dart';
import 'package:currencies_pages/bloc/crypto/states.dart';
import 'package:currencies_pages/bloc/currency/bloc.dart';
import 'package:currencies_pages/bloc/currency/events.dart';
import 'package:currencies_pages/bloc/currency/states.dart';
import 'package:currencies_pages/bloc/localData/bloc.dart';
import 'package:currencies_pages/bloc/localData/events.dart';
import 'package:currencies_pages/model/crypto.dart';
import 'package:currencies_pages/model/currencies.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';

import '../constants.dart';
import '../styles.dart';
import '../tools.dart';
import 'add_ticker_screen.dart';
import 'config_screen.dart';

double degToRad(double deg) => deg * (pi / 180.0);

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

const double _heightForSignal = 50;

class StreamWidgetBuilder {
  Widget? widget;
  void init() {
    widget = Container();
  }
  void addStreamBuilder() {

  }
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {

  bool _isInForeground = true;

  StreamController<Map<Currency_Pairs, Crypto?>>? cryptoController;

  Map<Currency_Type, num> previousCurrencies = {};
  String succeedTime = '';
  Statuses lastStatus = Statuses.online;
  double _signalHeight = _heightForSignal;
  bool topLoading = false;

  double yScrollPosition = 0;
  bool dropped = false;

  List<ValueNotifier<Crypto>> streamsNotifiers = [];

  final ValueNotifier<double> _topLoaderHeight = ValueNotifier<double>(0);

  final ValueNotifier<Orientation> orientationUI = ValueNotifier<Orientation>(Orientation.portrait);

  final ValueNotifier<bool> isEditingMode = ValueNotifier<bool>(false);

  Tween<double> _rotationTween = Tween(begin: 360, end: 0);
  late Animation<double> animation;
  late Animation<Color?> animation1;
  late AnimationController controller;
  ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    _initRates();
    _initCryptoWebSocket();
    WidgetsBinding.instance!.addObserver(this);

    _scrollController.addListener(() {
      if(_scrollController.hasClients) {
        if(_scrollController.position.pixels <= 0 && !dropped) {
          yScrollPosition = - _scrollController.position.pixels;
        }
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
  _initRates() {
    context.read<CurrenciesBloc>().add(CurrenciesEvents.initGetRate);
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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(LayoutStyles.appbarHeight),
          child: AppBar(
            title: Text("Rates"),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.settings,
                ),
                onPressed: () async {
                  isEditingMode.value = false;
                  final delay1 = await Navigator.push(context, MaterialPageRoute(builder: (context) =>
                      BlocProvider.value(
                        value: BlocProvider.of<LocalDataBloc>(context),
                        child: ConfigScreen(),
                      )
                  ));
                  context.read<CurrenciesBloc>().add(CurrenciesEvents.getRate);
                  controller.duration = Duration(milliseconds: (delay1 * 1000).toInt());
                  controller.value = 0;
                  controller.forward();
                },
              ),
              ValueListenableBuilder<bool>(
                  valueListenable: isEditingMode,
                  builder: (_, mode,__) {
                    return TextButton(
                      onPressed: () {isEditingMode.value = !mode;},
                      child: Text(mode ? 'Done' : 'Edit', style: TextStyle(color: Colors.blue[400]),),
                    );}
                  ),
            ],
          ),
        ),
        body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: _body()),
    );
  }

  Widget _body() {
      return OrientationBuilder(
        builder: (_, orientation) {
          orientationUI.value = orientation;
          return Column(
            children: [
              topLoading
                  ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: CircularProgressIndicator(),)
                  : ValueListenableBuilder<double>(
                builder: (context, double value, child) {
                  return SizedBox(height: value);
                }, valueListenable: _topLoaderHeight,
              ),

              Expanded(
                child: BlocBuilder<CurrenciesBloc, CurrenciesState>(builder: (BuildContext context, CurrenciesState state) {
                  // if(!_isInForeground) {
                  //   if(state is CurrenciesLoaded) {
                  //     return _bodyUI(state.currencies);
                  //   }
                  //   if(state is LocalCurrenciesLoaded) {
                  //     return _bodyUI(state.currencies);
                  //   }
                  // }
                  // @TODO BINANCE WITH RESTAPI BODY

                  if(state is CurrenciesLoaded) {
                    // context.read<LocalDataBloc>().add(StoreCurrencies(currencies: state.currencies));
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
                  }
                  return _bodyUI();

                  // if(state is LocalCurrenciesLoaded) {
                  //   Timer(const Duration(seconds: 2), () {
                  //     _loadRates();
                  //     context.read<CryptoBloc>().add(RetryConnection());
                  //   });
                  //   controller.duration = Duration(milliseconds: (state.currencies.delay * 1000).toInt());
                  //   return _bodyUI(state.currencies);
                  // }
                  return Container();
                }, buildWhen: (state1, state2) {
                  return !(state1 is LocalCurrenciesLoaded && state2 is LocalCurrenciesLoaded)  && state2 is! CurrenciesLoading;
                }),
              ),
              BlocBuilder<CurrenciesBloc, CurrenciesState>(builder: (BuildContext context, CurrenciesState state) {
                if(!_isInForeground) {
                  // if(state is CurrenciesLoaded || state is LocalCurrenciesLoaded || state is CurrenciesLoading) {
                    controller.value = 0;
                    return _footerUI(status: Statuses.offline);
                  // }
                }
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
          );
        }
      );
  }
  Widget _bodyUI() {
    return BlocBuilder<CryptoBloc, CryptoState>(builder: (BuildContext context, CryptoState state) {
      print(state);
      if(state is CryptoError) {
        return Container();
      }
      if(state is CryptoLoading) {
        return CryptoLoading(styles: PortraitStyles(),);
      }
      if(state is LocalCryptoLoaded) {
        print(state.currencies);
        return _UI(items: [_localCryptoLoaded(state.currencies)]);
      }
      if(state is CryptoLoaded) {
        return _UI(items: [_cryptoLoaded(state.streamController, state.confirmationDetails)]);
      }
      if(state is CryptoEmpty) {
        return _banner();
      }
      return Container();
    });

  }

  // @TODO BINANCE WITH RESTAPI BODYUI
  // Widget _bodyUI(Currencies currencies) {
  //   // final f = intl.NumberFormat();
  //   // Color initColor = Theme.of(context).accentColor;
  //   final items = currencies.arrayOfCurrencies.asMap().entries.map((entry) {
  //     final currency = entry.value;
  //     if(entry.key == 0) {
  //       return BlocBuilder<CryptoBloc, CryptoState>(builder: (BuildContext context, CryptoState state) {
  //         // print(state);
  //         if(state is CryptoError) {
  //           return Container();
  //         }
  //         if(state is CryptoLoading) {
  //           return CryptoLoading(styles: PortraitStyles(),);
  //         }
  //         if(state is LocalCryptoLoaded) {
  //           print(state.currencies);
  //           return _localCryptoLoaded(state.currencies);
  //         }
  //         if(state is CryptoLoaded) {
  //           return _cryptoLoaded(state.streamController, state.confirmationDetails);
  //         }
  //         if(state is CryptoEmpty) {
  //           return _banner();
  //         }
  //         return Container();
  //       });
  //     }
  //     if(previousCurrencies.isNotEmpty) {
  //       if(currency is Currency) {
  //         if(currency is Currency) {
  //           if(currency.price < previousCurrencies[currency.type]!) {
  //             // initColor = Colors.red;
  //           }
  //           if(currency.price > previousCurrencies[currency.type]!) {
  //             // initColor = Colors.blue;
  //           }
  //         }
  //       }
  //     }
  //     return Container();
  //   }).toList();
  //
  //   previousCurrencies = currencies.getCurrenciesAndTheirRates();
  //
  //   if(topLoading) {
  //     Future.delayed(Duration(seconds: 1), () async {
  //       setState(() {
  //         topLoading = false;
  //       });
  //       controller.reset();
  //     });
  //   }
  //
  //   return _UI(items: items);
  // }

  Widget _UI({required List<Widget> items}) {
    return _notifListener(
      child: Column(
        children: items,
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
    return SizedBox(
      height: LayoutStyles.footerHeight - 2 * LayoutStyles.footerPadding,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: LayoutStyles.footerPadding),
        // padding: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child:
              Text(succeedTime, style: TextStyle(fontSize: SucceedDatetime.fontSize)),
            ),

            Spacer(),

            AnimatedBuilder(
              animation: animation,
              builder: (_, snapshot) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CustomPaint(
                    painter: status1 != Statuses.offline
                        ? Painter(sweepAngle: animation.value, color: animation1.value == null ? Colors.green : animation1.value!, status: status1)
                        : Painter(sweepAngle: degToRad(20670), color: Colors.red, status: status1),
                    size: Size(RingStyles.ringSize,RingStyles.ringSize),
                  ),
                );
              },
            ),

            TextButton(
              onPressed: () async {
                isEditingMode.value = false;

                await Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    BlocProvider(
                      create: (BuildContext context) => LocalDataBloc(localDataRepo: LocalDataProvider()),
                      child: AddTickerScreen(),
                    ),
                ));
                context.read<CryptoBloc>().add(CheckIfObjIsEmpty());

              },
               child: Text('Add ticker', style: TextStyle(color: Colors.blue[400]),),
            )
          ],
        ),
      ),
    );
  }
   Function(CurrencyStyles styles, Orientation orientation) _orientatedCurrencyWidget({required String name, required String price}) {
    return (CurrencyStyles styles, Orientation orientation) {
      return _listenableCurrencyWidget(styles: styles,price: price,name: name, orientation: orientation);
    };
  }

  Future<bool> _showConfirmDialog(List<Currency_Pairs> confirmationDetails) async {
    controller.stop();
    final d = confirmationDetails;
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext alertContext) {
        final getName = CryptoFromBackendHelper.getNameByCurrencyType;
        return AlertDialog(
          title: Text(d.length > 1 ? 'Warning' : 'Confirmation'),
          content: Text(
              d.length > 1
                  ? 'Are you sure want to delete ${getName(d[0])} pair? This pairs will be deleted too: ${d.skip(1).map((e) => getName(e))}'
                  : 'Are you sure want to delete this pair?'),
          actions: <Widget>[
            TextButton(
              child: const Text('no'),
              onPressed: () {
                Navigator.pop(alertContext);
                context.read<CryptoBloc>().add(NotConfirmedRemovePair());
                controller.forward();
              },
            ),
            TextButton(
              child: const Text('confirm'),
              onPressed: () {
                Navigator.pop(alertContext);
                context.read<CryptoBloc>().add(ConfirmedRemovePair(pairs: confirmationDetails));
                controller.forward();
              },
            ),
          ],
        );
      },
    );
    return false;
  }

  Widget _banner() {
    return Container(
        height: 150,
        child: Center(
            child: Text('Please add some tickers',
              style: TextStyle(fontSize: PortraitStyles().currencyNameFontSize()),)
        )
    );
  }

  Widget _cryptoLoaded(StreamController<Map<Currency_Pairs, Crypto?>> streamController,
      List<Currency_Pairs> confirmationDetails,) {
    // marker
    if(confirmationDetails.length != 0) {
      Future.delayed(Duration.zero, () => _showConfirmDialog(confirmationDetails));
    }

    if(cryptoController == null) {
      cryptoController = streamController;
    }

    return StreamBuilder<Map<Currency_Pairs, Crypto?>>(
      stream: streamController.stream,
      builder: (_, snapshot) {

        if(!snapshot.hasData) {
          context.read<CryptoBloc>().add(CheckIfObjIsEmpty());
          return CryptoLoading(styles: PortraitStyles(),);
        }
        if(snapshot.data!.length == 0) {
          return _banner();
        }
        final currencies = snapshot.data!;
        context.read<LocalDataBloc>().add(StoreCurrencies(currencies: currencies));

        final items = currencies.values.map((crypto) {
          if(crypto == null) {
            return null;
          }
          return _orientatedCurrencyWidget(price: crypto.price, name: crypto.name);
        }).toList();
        return ValueListenableBuilder<Orientation>(
          valueListenable: orientationUI,
          builder: (_, orientation, __) {
            final styles = orientation == Orientation.portrait ? PortraitStyles() : LandscapeStyles();

            final styledItems = items.map<Widget>((e) {
              if(e == null) {
                return _cryptoWaiter();
              }
              return e(styles, orientation);
            }).toList();
            if (orientation == Orientation.portrait) {

              return ValueListenableBuilder<bool>(
                  valueListenable: isEditingMode,
                  builder: (_, mode, __) {
                    if(mode) {
                      var wrap = ReorderableWrap(
                        onReorder: (oldIdx, newIdx) {
                          final pair = currencies.keys.toList()[oldIdx];
                          context.read<CryptoBloc>().add(ReorderPair(newIdx: newIdx, pair: pair));
                        },
                        children: styledItems,
                      );
                      return SingleChildScrollView(child: wrap);
                    }

                    return SingleChildScrollView(
                        child: Column(
                            children: styledItems
                        )
                    );
                  });
            }
            if (orientation == Orientation.landscape) {

              return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height - (LayoutStyles.appbarHeight + LayoutStyles.footerHeight),
                  child: Swiper(
                    pagination: const SwiperPagination(
                      alignment: Alignment.bottomCenter,
                      builder: DotSwiperPaginationBuilder(
                        color: Colors.grey,
                      ),
                    ),
                    itemCount: items.length,
                    itemBuilder: (BuildContext context, int index) => styledItems[index]
                    )
              );
            }
            return Container();
          }
        );
      }
    );
  }

  void _onDeletePair(String name) {
    context.read<CryptoBloc>().add(CryptoRemovePair(pair: CryptoFromBackendHelper.getCurrencyTypeByName(name)));
  }

  Widget _listenableCurrencyWidget({required CurrencyStyles styles, required String price, required String name, required Orientation orientation}) {

    return ValueListenableBuilder<bool>(
      valueListenable: isEditingMode,
      builder: (_, mode, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if(mode && orientation == Orientation.portrait) IconButton(onPressed: () => _onDeletePair(name), icon: Icon(Icons.remove_circle_sharp, color: Colors.red,)),

          Expanded(
            child: CurrencyWidget(
              styles: styles,
              animated: false,
              currencyPrice: price,
              finalColor: Theme.of(context).accentColor,
              currencyName: name,
              deleteIcon: orientation == Orientation.landscape && mode,
              onDeleteIconPress: () => _onDeletePair(name)
            ),
          ),

          if(mode && orientation == Orientation.portrait) IconButton(onPressed: () => {}, icon: Icon(Icons.format_align_justify_outlined )),

        ],
      ),
    );
  }

  Widget _cryptoWaiter() {
    return ValueListenableBuilder(
        valueListenable: orientationUI,
        builder: (_, orientation, __) {
          final styles = orientation == Orientation.portrait ? PortraitStyles() : LandscapeStyles();
          return SizedBox(
              height: styles.currencyWidgetHeight(),
              child: Center(
                  child:Text('...', style: TextStyle(fontSize:40))));
        }
    );
  }

  Widget _localCryptoLoaded(Map<Currency_Pairs, Crypto?> currencies) {
    //@TODO IMPLEMENT LOCAL DELETING
    final items = currencies.values.map((crypto) {
      if(crypto == null) {
        return null;
      }
      return _orientatedCurrencyWidget(price: crypto.price, name: crypto.name);
    }).toList();


    return ValueListenableBuilder<Orientation>(
        valueListenable: orientationUI,
        builder: (_, orientation, __) {
          final styles = orientation == Orientation.portrait ? PortraitStyles() : LandscapeStyles();
          final styledItems = items.where((element) => element!=null).map<Widget>((e) {
            return e!(styles, orientation);
          }).toList();
          if(orientation == Orientation.portrait) {
            return ValueListenableBuilder<bool>(
                valueListenable: isEditingMode,
                builder: (_, mode, __) {
                  if(mode) {
                    final wrap = ReorderableWrap(
                      onReorder: (oldIdx, newIdx) {
                        final pair = currencies.keys.toList()[oldIdx];
                        context.read<CryptoBloc>().add(ReorderPair(newIdx: newIdx, pair: pair));
                      },
                      children: styledItems,
                    );
                    return SingleChildScrollView(child: wrap,);
                  }
                  return SingleChildScrollView(
                      child: Column(
                          children: styledItems
                      )
                  );
                });
          }
          if(orientation == Orientation.landscape) {
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height - (LayoutStyles.appbarHeight + LayoutStyles.footerHeight),
              child: Swiper(
                  pagination: const SwiperPagination(
                    alignment: Alignment.bottomCenter,
                    builder: DotSwiperPaginationBuilder(
                      color: Colors.grey,
                    ),
                  ),
                  itemCount: styledItems.length,
                  itemBuilder: (BuildContext context, int index) => styledItems[index])
            );
          }
            return Container();
      },
    );
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
    print('dispose');
    controller.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();

  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if(state == AppLifecycleState.resumed) {
      context.read<CryptoBloc>().add(CryptoInitConnection());
    } else {
      context.read<CryptoBloc>().add(CryptoCloseAllConnections());
    }
    setState(() {
      _isInForeground = state == AppLifecycleState.resumed;
    });
  }
}

class CryptoLoading extends StatefulWidget {
  final CurrencyStyles styles;
  const CryptoLoading({Key? key, required this.styles}) : super(key: key);

  @override
  _CryptoLoadingState createState() => _CryptoLoadingState();
}

class _CryptoLoadingState extends State<CryptoLoading> {
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
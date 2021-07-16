import 'dart:async';
import 'dart:core';
import 'dart:ui';

import 'package:currencies_pages/api/currenciesProvider.dart';
import 'package:currencies_pages/model/graphic_price.dart';
import 'package:currencies_pages/screens/currency_graphic.dart';
import 'package:currencies_pages/widgets/bottom_circle_loader.dart';
import 'package:currencies_pages/widgets/crypto_loader.dart';
import 'package:currencies_pages/widgets/currency_widget.dart';
import 'package:currencies_pages/widgets/scroll_notification_listener.dart';
import 'package:reorderables/reorderables.dart';
import 'package:currencies_pages/bloc/crypto/bloc.dart';
import 'package:currencies_pages/bloc/crypto/events.dart';
import 'package:currencies_pages/bloc/crypto/states.dart';
import 'package:currencies_pages/bloc/currency/bloc.dart';
import 'package:currencies_pages/bloc/currency/events.dart';
import 'package:currencies_pages/bloc/currency/states.dart';
import 'package:currencies_pages/bloc/localData/bloc.dart';
import 'package:currencies_pages/bloc/localData/events.dart';
import 'package:currencies_pages/model/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_swiper_null_safety/flutter_swiper_null_safety.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../constants.dart';
import '../styles.dart';
import '../tools.dart';
import 'add_ticker_screen.dart';
import 'config_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  Map<String, ChartSeriesController?> _chartSeriesController = {};

  Map<String, List<GraphicPrice>> chartData = {};

  var firstCryptoPrices = {};

  var itemsLength = 0;
  var key = UniqueKey();

  bool _isInForeground = true;

  Map<String, StreamController<Crypto?>> cryptoController = {};

  Timer? retryConnectionTimer;

  Map<String, String> previousCurrencies = {};
  String succeedTime = '';
  Statuses lastStatus = Statuses.online;
  bool topLoading = false;
  double _signalHeight = heightForSignal;

  List<ValueNotifier<Crypto>> streamsNotifiers = [];

  final ValueNotifier<double> _topLoaderHeight = ValueNotifier<double>(0);

  final ValueNotifier<Orientation> orientationUI = ValueNotifier<Orientation>(Orientation.portrait);

  final ValueNotifier<bool> isEditingMode = ValueNotifier<bool>(false);

  Tween<double> _rotationTween = Tween(begin: 360, end: 0);
  late Animation<double> animation;
  late Animation<Color?> animation1;
  late AnimationController controller;
  @override
  void initState() {

    _initRates();
    _initCryptoWebSocket();
    WidgetsBinding.instance!.addObserver(this);

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
            context.read<CurrenciesBloc>().add(GetRate());
          }

        });
    animation1 = ColorTween(begin: Colors.green, end: Colors.grey[700])
          .animate(controller);
    super.initState();
  }
  _initRates() {
    context.read<CurrenciesBloc>().add(GetBinance());
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
                  if(delay1 != null) {
                    context.read<CurrenciesBloc>().add(GetRate());
                    controller.duration = Duration(milliseconds: (delay1 * 1000).toInt());
                    controller.value = 0;
                    controller.forward();
                  }
                },
              ),
              ValueListenableBuilder<bool>(
                  valueListenable: isEditingMode,
                  builder: (_, mode,__) {
                    return TextButton(
                      onPressed: () {
                        isEditingMode.value = !mode;
                        },
                      child: Text(mode ? 'Done' : 'Edit', style: TextStyle(color: Colors.blue[400]),),
                    );
                  }),
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
              BlocBuilder<CryptoBloc, CryptoState>(builder: (BuildContext context, CryptoState state) {
                  if(state is CryptoClosingState) {
                    return Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Center(child: SizedBox(width:40,height:40,child: CircularProgressIndicator()),)
                          ),
                        )
                      ],
                    );
                  }
                  if(state is CryptoModal) {
                    Future.delayed(Duration.zero, () => _showConfirmDialog(state.confirmationDetails, state.requestFrom));
                  }
                  return Container();
                }, buildWhen: (state1, state2) => state2 is CryptoModal || state2 is CryptoEmptyState || state2 is CryptoClosingState,
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

                  if(state is CurrenciesLoaded) {
                    controller.duration = Duration(milliseconds: (state.currencies.delay * 1000).toInt());
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
                  controller.value = 0;
                  return _footerUI(status: Statuses.offline);
                }

                if(state is CurrenciesLoaded) {
                  succeedTime = state.currencies.time;
                }

                return BlocBuilder<CryptoBloc, CryptoState>(builder: (BuildContext context, CryptoState state) {
                    if(state is LocalCryptoLoaded) {
                      return _footerUI(status: Statuses.offline);
                    }
                    if(state is CryptoLoaded) {
                      if(controller.status == AnimationStatus.dismissed) {
                        controller.forward();
                      }
                      if(controller.status == AnimationStatus.completed) {
                        Future.delayed(Duration.zero, () async {
                          controller.value = 0;
                          controller.forward();
                        });
                      }
                      return _footerUI(status: Statuses.online);
                    }
                    if(state is CryptoError) {
                      return _footerUI(status: Statuses.offline);
                    }
                    if(state is CryptoLoading) {
                      return _footerUI(status: Statuses.unknown);
                    }

                    return Text('unknown footer state');
                }, buildWhen: (_, state2) => state2 is! CryptoEmptyState && state2 is! CryptoModal
                    && state2 is! CryptoEmpty && state2 is! CryptoClosingState
                );
              })

          // BlocBuilder<CurrenciesBloc, CurrenciesState>(builder: (BuildContext context, CurrenciesState state) {
              //   if(!_isInForeground) {
              //     if(state is CurrenciesLoaded || state is LocalCurrenciesLoaded || state is CurrenciesLoading) {
              //       controller.value = 0;
              //       return _footerUI(status: Statuses.offline);
              //     }
              //   }
              //   if(state is CurrenciesLoaded) {
              //     succeedTime = state.currencies.time;
              //     return _footerUI(status: Statuses.online);
              //   }
              //   if(state is LocalCurrenciesLoaded) {
              //     succeedTime = state.currencies.time;
              //     return _footerUI(status: Statuses.offline);
              //   }
              //   if(state is CurrenciesLoading) {
              //     return _footerUI(status: Statuses.unknown);
              //   }
              //   return Container();
              // })
            ],
          );
        }
      );
  }
  Widget _bodyUI() {
    return BlocBuilder<CryptoBloc, CryptoState>(builder: (BuildContext context, CryptoState state) {
      if(retryConnectionTimer != null) {
        retryConnectionTimer = null;
      }
      if(topLoading) {
        Future.delayed(Duration(seconds: 1), () async {
          setState(() {
            topLoading = false;
          });
          controller.reset();
        });
      }
      if(state is CryptoError) {
        return Container();
      }
      if(state is CryptoLoading) {
        return CryptoLoader(styles: PortraitStyles(),);
      }
      if(state is LocalCryptoLoaded) {
        retryConnectionTimer = Timer(Duration(seconds: 2), () {
          context.read<CryptoBloc>().add(RetryConnection());
        });

        return _UI(items: [_localCryptoLoaded(state.currencies)]);
      }
      if(state is CryptoLoaded) {

        return _UI(items: [_cryptoLoaded(state.streamControllers)]);
      }
      if(state is CryptoEmpty) {
        return _banner();
      }
      return Container();
    }, buildWhen: (_,state2) => state2 is! CryptoEmptyState && state2 is! CryptoModal && state2 is! CryptoClosingState,);

  }

  SfCartesianChart _buildLiveLineChart(String cryptoName) {
    return SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: DateTimeAxis(),
        primaryYAxis: NumericAxis(
            axisLine: const AxisLine(width: 0),
            majorTickLines: const MajorTickLines(size: 0)),
        series: <LineSeries<GraphicPrice, DateTime>>[
          LineSeries<GraphicPrice, DateTime>(
            onRendererCreated: (ChartSeriesController controller) {
              _chartSeriesController[cryptoName] = controller;
            },
            dataSource: chartData[cryptoName] == null ? [] : chartData[cryptoName]!,
            color: const Color.fromRGBO(192, 108, 132, 1),
            xValueMapper: (GraphicPrice sales, _) => sales.time,
            yValueMapper: (GraphicPrice sales, _) => double.parse(sales.price),
            animationDuration: 0,
          )
        ]);
  }

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
                        : Painter(sweepAngle: Utils.degToRad(20670), color: Colors.red, status: status1),
                    size: Size(RingStyles.ringSize,RingStyles.ringSize),
                  ),
                );
              },
            ),

            TextButton(
              onPressed: () async {
                isEditingMode.value = false;
                // await Navigator.push(context, MaterialPageRoute(builder: (context) =>
                //     BlocProvider(
                //       create: (BuildContext context) => LocalDataBloc(localDataRepo: LocalDataProvider()),
                //       child: AddTickerScreen(),
                //     ),
                // ));
                await Navigator.push(context, MaterialPageRoute(builder: (context) =>
                    MultiBlocProvider(
                      providers: [
                        BlocProvider(create: (BuildContext context) => CurrenciesBloc(currencyRepo: CurrencyProvider()),),
                        BlocProvider.value(
                          value: BlocProvider.of<LocalDataBloc>(context),
                          child: ConfigScreen(),
                        )
                        // BlocProvider(create: (BuildContext context) => LocalDataBloc.getInstance(),),
                      ],
                      child: AddTickerScreen(),)
                ));
                context.read<CryptoBloc>().add(CheckIfObjIsEmpty());
              },
               child: Padding(
                 padding: EdgeInsets.only(left: 14.0, right: MediaQuery.of(context).orientation == Orientation.portrait ? 8 : 36),
                 child: Text('Add ticker', style: TextStyle(color: Colors.blue[400]),),
               ),
            )
          ],
        ),
      ),
    );
  }

  Widget Function(CurrencyStyles styles)
   _orientatedCurrencyWidget({required Crypto crypto, required Modal_RequestType requestFrom}) {
    return (CurrencyStyles styles) {
      return _listenableCurrencyWidget(styles: styles, crypto: crypto, requestFrom: requestFrom);
    };
  }

  Future<bool> _showConfirmDialog(String confirmationDetails, Modal_RequestType requestFrom) async {
    controller.stop();
    final d = confirmationDetails;
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext alertContext) {
        return AlertDialog(
          title: Text(d.length > 1 ? 'Warning' : 'Confirmation'),
          content: Text(
              d.length > 1
                  ? 'Are you sure want to delete $d pair?'
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
                context.read<CryptoBloc>().add(ConfirmedRemovePair(pair: d, requestFrom: requestFrom));
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

  Widget _cryptoLoaded(Map<String, StreamController<Crypto?>> streamControllers) {

    // marker
    cryptoController = streamControllers;
    final List<Widget> items = streamControllers.values.map((e) {
      return StreamBuilder<Crypto?>(
          stream: e.stream,
          builder: (_, snapshot) {
            if(snapshot.hasError) {
              if(snapshot.error is ClosedCrypto) {
                return Container();
              }
            }
            if(!snapshot.hasData) {
              return CryptoLoader(styles: PortraitStyles(),);
            }
            final crypto = snapshot.data!;
            if(!previousCurrencies.containsKey(crypto.name)) {
              previousCurrencies[crypto.name] = crypto.price;
            }
            // if(chartData.containsKey(crypto.name)) {
            //   chartData[crypto.name]!.add(GraphicPrice(
            //       time: DateTime.now(), open: crypto.price, close: crypto.price));
            //
            //   if(chartData[crypto.name]!.length == 20) {
            //     chartData[crypto.name]!.removeAt(0);
            //     _chartSeriesController[crypto.name]!.updateDataSource(
            //       addedDataIndexes: <int>[chartData[crypto.name]!.length - 1],
            //       removedDataIndexes: <int>[0],
            //     );
            //   } else {
            //     _chartSeriesController[crypto.name]?.updateDataSource(
            //       addedDataIndexes: <int>[chartData.length - 1],
            //     );
            //   }
            // } else {
            //   chartData[crypto.name] = [GraphicPrice(time: DateTime.now(), open: crypto.price, close: crypto.price)];
            // }

            return _orientatedCurrencyWidget(crypto: crypto, requestFrom: Modal_RequestType.internet)(PortraitStyles());
      });
    }).toList();
    // final wrap = ReorderableWrap(
    //   onReorder: (oldIdx, newIdx) {
    //     final pair = streamControllers.keys.toList()[oldIdx];
    //     context.read<CryptoBloc>().add(ReorderPair(newIdx: newIdx, pair: pair));
    //   },
    //   children: items,
    // );
    return Column(
      children: items
    );
    // return StreamBuilder<Map<Currency_Pairs, Crypto?>>(
    //   stream: streamController.stream,
    //   builder: (_, snapshot) {
    //     if(snapshot.hasError) {
    //       if(snapshot.error is CryptoError) {
    //         context.read<CryptoBloc>().add(GetLocalCrypto());
    //       }
    //       return Container();
    //     }
    //
    //     if(!snapshot.hasData) {
    //       context.read<CryptoBloc>().add(CheckIfObjIsEmpty());
    //       return CryptoLoader(styles: PortraitStyles(),);
    //     }
    //
    //     final currencies = snapshot.data!;
    //
    //     if(currencies.isEmpty) {
    //       context.read<CryptoBloc>().add(CheckIfObjIsEmpty());
    //     }
    //     context.read<LocalDataBloc>().add(StoreCurrencies(currencies: currencies));
    //
    //     final items = currencies.values.map((crypto) {
    //       if(crypto == null) {
    //         return null;
    //       }
    //       if(chartData.containsKey(crypto.name)) {
    //         chartData[crypto.name]!.add(GraphicPrice(
    //             time: DateTime.now(), open: crypto.price, close: crypto.price));
    //
    //         // if(chartData.length == 20) {
    //         //   chartData[crypto.name]!.removeAt(0);
    //         //   _chartSeriesController[crypto.name]!.updateDataSource(
    //         //     addedDataIndexes: <int>[chartData[crypto.name]!.length - 1],
    //         //     removedDataIndexes: <int>[0],
    //         //   );
    //         // } else {
    //         //   _chartSeriesController[crypto.name]?.updateDataSource(
    //         //     addedDataIndexes: <int>[chartData.length - 1],
    //         //   );
    //         // }
    //       } else {
    //         chartData[crypto.name] = [GraphicPrice(time: DateTime.now(), open: crypto.price, close: crypto.price)];
    //       }
    //       if(!firstCryptoPrices.containsKey(crypto.name)) {
    //         firstCryptoPrices[crypto.name] = crypto.price;
    //       }
    //       return _orientatedCurrencyWidget(crypto: crypto, requestFrom: Modal_RequestType.internet);
    //     }).toList();
    //
    //     return ValueListenableBuilder<Orientation>(
    //       valueListenable: orientationUI,
    //       builder: (_, orientation, __) {
    //         final styles = orientation == Orientation.portrait ? PortraitStyles() : LandscapeStyles();
    //
    //         final styledItems = items.map<Widget>((e) {
    //           if(e == null) {
    //             return _cryptoWaiter();
    //           }
    //           return e(styles);
    //         }).toList();
    //         if (orientation == Orientation.portrait) {
    //
    //           return ValueListenableBuilder<bool>(
    //               valueListenable: isEditingMode,
    //               builder: (_, mode, __) {
    //                 if(mode) {
    //                   var wrap = ReorderableWrap(
    //                     onReorder: (oldIdx, newIdx) {
    //                       final pair = currencies.keys.toList()[oldIdx];
    //                       context.read<CryptoBloc>().add(ReorderPair(newIdx: newIdx, pair: pair));
    //                     },
    //                     children: styledItems,
    //                   );
    //                   return SingleChildScrollView(child: wrap);
    //                 }
    //
    //                 return SingleChildScrollView(
    //                     child: Column(
    //                         children: styledItems
    //                     )
    //                 );
    //               });
    //         }
    //         if(orientation == Orientation.landscape) {
    //           if(itemsLength != items.length) { // FIXED BUG line 110 pos 12: flutter: '_positions.isNotEmpty
    //             itemsLength = items.length;
    //             key = UniqueKey();
    //           }
    //           return SizedBox(
    //               width: MediaQuery.of(context).size.width,
    //               height: MediaQuery.of(context).size.height - (LayoutStyles.appbarHeight + LayoutStyles.footerHeight),
    //               child: Swiper(
    //                 key: key,
    //                 pagination: const SwiperPagination(
    //                   alignment: Alignment.bottomCenter,
    //                   builder: DotSwiperPaginationBuilder(
    //                     color: Colors.grey,
    //                   ),
    //                 ),
    //
    //                 itemCount: items.length,
    //                 itemBuilder: (BuildContext context, int index) => styledItems[index]
    //               )
    //           );
    //         }
    //         return Container();
    //       }
    //     );
    //   }
    // );
  }

  void _onDeletePair(String name, Modal_RequestType requestFrom,) {
      context.read<CryptoBloc>().add(CryptoRemovePair(pair: name, requestFrom: requestFrom));
  }

  Widget _listenableCurrencyWidget({required Modal_RequestType requestFrom, required CurrencyStyles styles, required Crypto crypto}) {

    return ValueListenableBuilder<bool>(
      valueListenable: isEditingMode,
      builder: (_, mode, __) {
        return InkWell(
          onTap: !mode ? () {
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (BuildContext context) => CurrenciesBloc(currencyRepo: CurrencyProvider()),
                  child: CurrencyGraphic(crypto: crypto, streamController: cryptoController[crypto.name]!,),
                )
            ));
          } : null,

          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if(mode && styles is PortraitStyles) IconButton(onPressed: () => _onDeletePair(crypto.name, requestFrom), icon: Icon(Icons.remove_circle_sharp, color: Colors.red,)),

              Expanded(
                child: CurrencyWidget(
                    oldPrice: previousCurrencies[crypto.name]!,
                    percent: crypto.changePercent,
                    styles: styles,
                    currencyPrice: crypto.price,
                    currencyName: crypto.name,
                    deleteIcon:  styles is LandscapeStyles && mode,
                    onDeleteIconPress: () => _onDeletePair(crypto.name, requestFrom)
                ),
              ),

            ],
          ),
        );
      }
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

  Widget _localCryptoLoaded(Map<String, Crypto?> currencies) {
    final items = currencies.values.map((crypto) {
      if(crypto == null) {
        return null;
      }
      return _orientatedCurrencyWidget(crypto: crypto, requestFrom: Modal_RequestType.local);
    }).toList();


    return ValueListenableBuilder<Orientation>(
        valueListenable: orientationUI,
        builder: (_, orientation, __) {
          final styles = orientation == Orientation.portrait ? PortraitStyles() : LandscapeStyles();
          final styledItems = items.where((element) => element!=null).map<Widget>((e) {
            return e!(styles);
          }).toList();
          if(orientation == Orientation.portrait) {
            return ValueListenableBuilder<bool>(
                valueListenable: isEditingMode,
                builder: (_, mode, __) {
                  if(mode) {
                    final wrap = ReorderableWrap(
                      onReorder: (oldIdx, newIdx) {
                        final pair = currencies.keys.toList()[oldIdx];
                        context.read<CryptoBloc>().add(LocalReorderPair(newIdx: newIdx, pair: pair));
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
            if(itemsLength != items.length) { // FIXED BUG line 110 pos 12: flutter: '_positions.isNotEmpty
              itemsLength = items.length;
              key = UniqueKey();
            }
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

  ScrollNotificationListener _notifListener({required Widget child}) {
    return ScrollNotificationListener(
      child: child,
      stopController: () {controller.stop();},
      setLoadingTrue: () {
        setState(() {
          topLoading = true;
        });
      },);
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
        // context.read<CurrenciesBloc>().add(CurrenciesEvents.getRate);
      });
      controller.stop();
    }
    _topLoaderHeight.value = 0;
  }
  @override
  void dispose() {
    if(retryConnectionTimer != null) retryConnectionTimer!.cancel();
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
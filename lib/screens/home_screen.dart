import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:math';

// import 'package:carousel_slider/carousel_slider.dart';
import 'package:currencies_pages/api/services.dart';
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
import 'package:intl/intl.dart' as intl;
import 'package:multiple_stream_builder/multiple_stream_builder.dart';
import 'dart:io' as devicishe;

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
  Currency_Type.eurusd: 'Евро/Доллар',
  Currency_Type.eur: 'Евро',
  Currency_Type.brent: 'Нефть Brent',
  Currency_Type.usd: 'Доллар',
};

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

enum Currency_Pairs {
  btcusd,
  ethusd,
  dogeusd,
  btcrub,
  btceur,
  eurusd,
  eurrub,
  usdrub
}
// ['btcusdt', 'ethusdt', 'btceur', 'dogeusdt']


class CryptoFromBackendHelper {
  static Map<Currency_Pairs, String> _nameByCurrencyType = {
    Currency_Pairs.btcusd: 'BTC-USD',
    Currency_Pairs.ethusd: 'ETH-USD',
    Currency_Pairs.dogeusd: 'DOGE-USD',
    Currency_Pairs.btcrub: 'BTC-RUB',
    Currency_Pairs.btceur: 'BTC-EUR',
    Currency_Pairs.usdrub: 'USD-RUB',
    Currency_Pairs.eurusd: 'EUR-USD',
    Currency_Pairs.eurrub: 'EUR-RUB',
  };
  static Currency_Pairs _getCurrencyType(Map<String, dynamic> crypto) {
    var stringType = crypto['s'].toLowerCase();

    if(stringType.endsWith('t')) {
      List<String> c = stringType.split("");
      c.removeLast();
      stringType = c.join();
    }
    return stringCurPairsToEnum(stringType);
  }
  static String _getPrice(Map<String, dynamic> crypto) {
    var price = ((double.parse(crypto['b']) + double.parse(crypto['a'])) / 2);
    return makeShortPrice(price);
  }
  static String getNameByCurrencyType(Currency_Pairs type) {
    return _nameByCurrencyType[type]!;
  }
  static String _getName(Map<String, dynamic> crypto) {
    return getNameByCurrencyType(_getCurrencyType(crypto));
  }
  static Currency_Pairs getCurrencyTypeByName(String name) {
    return _nameByCurrencyType.keys.firstWhere((element) => _nameByCurrencyType[element] == name);
  }
  static Crypto createCrypto(Map<String, dynamic> crypto) {
    var price = _getPrice(crypto);
    var type = _getCurrencyType(crypto);
    var name = _getName(crypto);
    return Crypto(name: name, price: price, type: type);
  }
}

String makeShortPrice(double price) {
  var stringPrice = price.toString();
  return stringPrice = stringPrice.length > 9 ? stringPrice.substring(0, 9) : stringPrice;
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {

  bool _isInForeground = true;

  List<StreamController> cryptoControllers = [];

  Map<Currency_Type, num> previousCurrencies = {};
  String succeedTime = '';
  Statuses lastStatus = Statuses.online;
  double _signalHeight = _heightForSignal;
  bool topLoading = false;

  double yScrollPosition = 0;
  bool dropped = false;

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
    _loadRates();
    _initCryptoWebSocket();
    WidgetsBinding.instance!.addObserver(this);

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
                  if(!_isInForeground) {
                    if(state is CurrenciesLoaded) {
                      return _bodyUI(state.currencies);
                    }
                    if(state is LocalCurrenciesLoaded) {
                      return _bodyUI(state.currencies);
                    }
                  }
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
                    return _bodyUI(state.currencies);
                  }
                  if(state is LocalCurrenciesLoaded) {
                    Timer(const Duration(seconds: 2), () {
                      _loadRates();
                      context.read<CryptoBloc>().add(RetryConnection());
                    });
                    controller.duration = Duration(milliseconds: (state.currencies.delay * 1000).toInt());
                    return _bodyUI(state.currencies);
                  }
                  return Container();
                }, buildWhen: (state1, state2) {
                  return !(state1 is LocalCurrenciesLoaded && state2 is LocalCurrenciesLoaded)  && state2 is! CurrenciesLoading;
                }),
              ),
              BlocBuilder<CurrenciesBloc, CurrenciesState>(builder: (BuildContext context, CurrenciesState state) {
                if(!_isInForeground) {
                  if(state is CurrenciesLoaded || state is LocalCurrenciesLoaded || state is CurrenciesLoading) {
                    controller.value = 0;
                    return _footerUI(status: Statuses.offline);
                  }
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

  Widget _bodyUI(Currencies currencies) {
    // final f = intl.NumberFormat();
    // Color initColor = Theme.of(context).accentColor;
    final items = currencies.arrayOfCurrencies.asMap().entries.map((entry) {
      final currency = entry.value;
      if(entry.key == 0) {
        return BlocBuilder<CryptoBloc, CryptoState>(builder: (BuildContext context, CryptoState state) {
          if(state is CryptoError) {
            return Container();
          }
          if(state is LocalCryptoLoaded) {
            return _localCryptoLoaded(state.cryptoList);
          }
          if(state is CryptoLoaded) {
            return _cryptoLoaded(state.cryptoInfo);
          }
          return Container();
        });
      }
      if(previousCurrencies.isNotEmpty) {
        if(currency is Currency) {
          if(currency is Currency) {
            if(currency.price < previousCurrencies[currency.type]!) {
              // initColor = Colors.red;
            }
            if(currency.price > previousCurrencies[currency.type]!) {
              // initColor = Colors.blue;
            }
          }
        }
      }
      return Container();
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

    return _UI(items: items);
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

  // Widget _portraitCarousel(List<Widget> items) {
  //   return ConstrainedBox(
  //       constraints:new BoxConstraints.loose(new Size(MediaQuery.of(context).size.width, 170.0)),
  //       child: ValueListenableBuilder<int>(
  //       builder: (_, int value, __) {
  //         return Swiper(
  //           pagination: new SwiperPagination(
  //               builder: DotSwiperPaginationBuilder(
  //                   color: Colors.grey
  //               ),
  //               margin: new EdgeInsets.all(10.0)
  //           ),
  //           itemCount: items.length,
  //           itemBuilder: (BuildContext context, int index) {
  //             return items[index];
  //           },
  //         );
  //       },
  //       valueListenable: portraitPageIndex,
  //     ),
  //   );
  // }

  Widget _cryptoLoaded(cryptoInfo) {
    if(cryptoControllers.isEmpty) {
      cryptoControllers = cryptoInfo;
    }
    var btcusd = '';
    var btcrub = '';
    var btceur = '';
    final i = cryptoInfo;

    final styles = PortraitStyles();
    SingleChildScrollView(
      child: Column(
        children: [
          ...(cryptoInfo as List).map((e) {
            return StreamBuilder(
              stream: e,
              builder: (_, snapshot) {
                if(!snapshot.hasData) {
                  return _cryptoWaiter();
                }
                final crypto = CryptoFromBackendHelper.createCrypto(jsonDecode(snapshot.data!.toString())['data']);
                if(crypto.type == Currency_Pairs.btcusd) btcusd = crypto.price;
                if(crypto.type == Currency_Pairs.btceur) btceur = crypto.price;
                if(crypto.type == Currency_Pairs.btcrub) btcrub = crypto.price;
                if(btcusd.isNotEmpty && btcrub.isNotEmpty
                    && (crypto.type == Currency_Pairs.btcusd || crypto.type == Currency_Pairs.btcrub)
                ) {
                  context.read<LocalDataBloc>().add(
                      StoreCrypto(crypto: Crypto(
                          name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.usdrub),
                          price: makeShortPrice(double.parse(btcrub) / double.parse(btcusd)),
                          type: Currency_Pairs.usdrub
                      )));
                }
                if(btceur.isNotEmpty && btcusd.isNotEmpty
                    && (crypto.type == Currency_Pairs.btceur || crypto.type == Currency_Pairs.btcusd)
                ) {
                  context.read<LocalDataBloc>().add(
                      StoreCrypto(crypto: Crypto(
                          name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.eurusd),
                          price: makeShortPrice(double.parse(btcusd) / double.parse(btceur)),
                          type: Currency_Pairs.eurusd
                      )));
                }
                if(btcrub.isNotEmpty && btceur.isNotEmpty
                    && (crypto.type == Currency_Pairs.btcrub || crypto.type == Currency_Pairs.btceur)
                ) {
                  context.read<LocalDataBloc>().add(
                      StoreCrypto(crypto: Crypto(
                          name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.eurrub),
                          price: makeShortPrice(double.parse(btcrub) / double.parse(btceur)),
                          type: Currency_Pairs.eurrub
                      )));
                }
                context.read<LocalDataBloc>().add(StoreCrypto(crypto: crypto));
                return _listenableCurrencyWidget(styles: styles,price:crypto.price,name:crypto.name);
              },
            );
          })
        ],
      ),
    );
    return ValueListenableBuilder(
      valueListenable: orientationUI,
      builder: (_, orientation, __) => StreamBuilder5<dynamic,dynamic,dynamic,dynamic, dynamic>(
        streams: Tuple5(i[0].stream, i[1].stream, i[2].stream, i[3].stream, i[4].stream),
        builder: (BuildContext context, Tuple5<AsyncSnapshot<dynamic>, AsyncSnapshot<dynamic>,
            AsyncSnapshot<dynamic>, AsyncSnapshot<dynamic>,AsyncSnapshot<dynamic>> snapshots) {
          final mapper = [snapshots.item1, snapshots.item2, snapshots.item3, snapshots.item4, snapshots.item5];
          var eurRubUsd = [btcusd, btcrub, btceur];
          if(orientation == Orientation.portrait) {
            final styles = PortraitStyles();
            return SingleChildScrollView(
              child: Column(
                  children: [
                    ...mapper.asMap().entries.map((e) {
                      final index = e.key;
                      if(!mapper[index].hasData) {
                        return _cryptoWaiter();
                      }

                      final crypto = CryptoFromBackendHelper.createCrypto(jsonDecode(mapper[index].data!.toString())['data']);
                      if(crypto.type == Currency_Pairs.btcusd) btcusd = crypto.price;
                      if(crypto.type == Currency_Pairs.btceur) btceur = crypto.price;
                      if(crypto.type == Currency_Pairs.btcrub) btcrub = crypto.price;
                      if(btcusd.isNotEmpty && btcrub.isNotEmpty
                        && (crypto.type == Currency_Pairs.btcusd || crypto.type == Currency_Pairs.btcrub)
                      ) {
                        context.read<LocalDataBloc>().add(
                            StoreCrypto(crypto: Crypto(
                                name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.usdrub),
                                price: makeShortPrice(double.parse(btcrub) / double.parse(btcusd)),
                                type: Currency_Pairs.usdrub
                            )));
                      }
                      if(btceur.isNotEmpty && btcusd.isNotEmpty
                          && (crypto.type == Currency_Pairs.btceur || crypto.type == Currency_Pairs.btcusd)
                      ) {
                        context.read<LocalDataBloc>().add(
                            StoreCrypto(crypto: Crypto(
                                name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.eurusd),
                                price: makeShortPrice(double.parse(btcusd) / double.parse(btceur)),
                                type: Currency_Pairs.eurusd
                            )));
                      }
                      if(btcrub.isNotEmpty && btceur.isNotEmpty
                          && (crypto.type == Currency_Pairs.btcrub || crypto.type == Currency_Pairs.btceur)
                      ) {
                        context.read<LocalDataBloc>().add(
                            StoreCrypto(crypto: Crypto(
                                name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.eurrub),
                                price: makeShortPrice(double.parse(btcrub) / double.parse(btceur)),
                                type: Currency_Pairs.eurrub
                            )));
                      }
                      context.read<LocalDataBloc>().add(StoreCrypto(crypto: crypto));
                      return _listenableCurrencyWidget(styles:styles,price:crypto.price,name:crypto.name);
                    }).toList(),
                    if(btcusd.isNotEmpty || btceur.isNotEmpty || btcrub.isNotEmpty)
                      ...[
                        btcusd.isNotEmpty && btcrub.isNotEmpty
                          ?
                            _listenableCurrencyWidget(
                                styles: styles,
                                price:makeShortPrice(double.parse(btcrub) / double.parse(btcusd)),
                                name:CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.usdrub)
                            )
                            :
                           _cryptoWaiter(),

                        btceur.isNotEmpty && btcusd.isNotEmpty
                            ?
                            _listenableCurrencyWidget(
                                styles: styles,
                                price:makeShortPrice(double.parse(btcusd) / double.parse(btceur)),
                                name:CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.eurusd)
                            )
                            : _cryptoWaiter(),
                        btcrub.isNotEmpty && btceur.isNotEmpty
                            ?
                            _listenableCurrencyWidget(
                                styles: styles,
                                price:makeShortPrice(double.parse(btcrub) / double.parse(btceur)),
                                name:CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.eurrub)
                            )
                            : _cryptoWaiter()
                      ]
                  ].map((e) => ConstrainedBox(
                    constraints: BoxConstraints.loose(Size(MediaQuery.of(context).size.width, styles.currencyWidgetHeight())),
                    child: e
                  )).toList(),
                ),
            );
          }

          if(orientation == Orientation.landscape) {
            final styles = LandscapeStyles();

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
                  itemCount: cryptoInfo.length + eurRubUsd.length,
                  itemBuilder: (BuildContext context, int index) {

                    mapper.asMap().entries.forEach((e) {
                      if(!e.value.hasData) {
                        return;
                      }
                      final crypto = CryptoFromBackendHelper.createCrypto(jsonDecode(e.value.data!.toString())['data']);

                      if(crypto.type == Currency_Pairs.btcusd) btcusd = crypto.price;
                      if(crypto.type == Currency_Pairs.btceur) btceur = crypto.price;
                      if(crypto.type == Currency_Pairs.btcrub) btcrub = crypto.price;
                    });

                    if(index >= cryptoInfo.length) {
                      if(index - cryptoInfo.length == 0) {
                        if (btcusd.isNotEmpty && btcrub.isNotEmpty) {
                          return _listenableCurrencyWidget(
                              styles:styles,
                              price:makeShortPrice(double.parse(btcrub) / double.parse(btcusd)),
                              name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.usdrub)
                          );
                        }
                      }
                      if(index - cryptoInfo.length == 1) {
                        if(btceur.isNotEmpty && btcusd.isNotEmpty) {
                          return _listenableCurrencyWidget(
                              styles:styles,
                              price:makeShortPrice(double.parse(btcusd) / double.parse(btceur)),
                              name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.eurusd)
                          );
                        }
                      }
                      if(index - cryptoInfo.length == 2) {
                        if(btcrub.isNotEmpty && btceur.isNotEmpty) {
                          return _listenableCurrencyWidget(
                              styles:styles,
                              price:makeShortPrice(double.parse(btcrub) / double.parse(btceur)),
                              name: CryptoFromBackendHelper.getNameByCurrencyType(Currency_Pairs.eurrub)
                          );
                        }
                      }
                      return _cryptoWaiter();
                    }

                    if(!mapper[index].hasData) {
                      return _cryptoWaiter();
                    }

                    final crypto = CryptoFromBackendHelper.createCrypto(jsonDecode(mapper[index].data!.toString())['data']);

                    context.read<LocalDataBloc>().add(StoreCrypto(crypto: crypto));

                    return Center(
                      child: _listenableCurrencyWidget(styles: styles,price: crypto.price,name: crypto.name)
                    );
                  },
                ),
              );
          }
          return Container();
          },
        ),
    );
  }

  void _onDeletePair(String name) {
    context.read<CryptoBloc>().add(CryptoRemovePair(pair: CryptoFromBackendHelper.getCurrencyTypeByName(name)));
  }

  Widget _listenableCurrencyWidget({required CurrencyStyles styles, required String price, required String name}) {

    return ValueListenableBuilder<bool>(
      valueListenable: isEditingMode,
      builder: (_, mode, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: CurrencyWidget(
              styles: styles,
              animated: false,
              currencyPrice: price,
              finalColor: Theme.of(context).accentColor,
              currencyName: name,
            ),
          ),
          if(mode) IconButton(onPressed: () => _onDeletePair(name), icon: Icon(Icons.remove_circle_sharp, color: Colors.red,))
        ],
      ),
    );
  }

  Widget _cryptoWaiter() {
    return Center(child:Text('...', style: TextStyle(fontSize:40)));
  }

  Widget _localCryptoLoaded(List<Crypto> cryptoList) {
    return ValueListenableBuilder(
        valueListenable: orientationUI,
        builder: (_, orientation, __) {
          if(orientation == Orientation.portrait) {
            final styles = PortraitStyles();
            return Column(children: cryptoList.map((crypto) {
              return _listenableCurrencyWidget(styles: styles, price: crypto.price, name: crypto.name);
            }).map((e) => ConstrainedBox(
                constraints: BoxConstraints.loose(Size(MediaQuery.of(context).size.width, styles.currencyWidgetHeight())),
                child: e
            )).toList());
          }
          if(orientation == Orientation.landscape) {
            final styles = LandscapeStyles();
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
                  itemCount: cryptoList.length,
                  itemBuilder: (BuildContext context, int index) =>
                    _listenableCurrencyWidget(styles: styles, name: cryptoList[index].name, price: cryptoList[index].price)
                  )
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
    cryptoControllers.forEach((element) {
      element.close();
    });
    super.dispose();
    WidgetsBinding.instance!.removeObserver(this);
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
                Text(
                    widget.currencyPrice.toString(),
                    style: TextStyle(
                        color: widget.finalColor,
                        fontSize: widget.styles.currencyPriceFontSize())),
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
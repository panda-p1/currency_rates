import 'dart:async';
import 'dart:core';
import 'dart:ui';

import 'package:currencies_pages/api/currenciesProvider.dart';
import 'package:currencies_pages/model/graphic_price.dart';
import 'package:currencies_pages/screens/currency_graphic.dart';
import 'package:currencies_pages/widgets/crypto_loader.dart';
import 'package:currencies_pages/widgets/currency_widget.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:currencies_pages/bloc/crypto/bloc.dart';
import 'package:currencies_pages/bloc/crypto/events.dart';
import 'package:currencies_pages/bloc/crypto/states.dart';
import 'package:currencies_pages/bloc/currency/bloc.dart';
import 'package:currencies_pages/bloc/currency/events.dart';
import 'package:currencies_pages/bloc/currency/states.dart';
import 'package:currencies_pages/bloc/localData/bloc.dart';
import 'package:currencies_pages/model/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../styles.dart';
import 'add_ticker_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {

  Map<String, List<GraphicPrice>> chartData = {};

  bool firstLaunch = true;

  var itemsLength = 0;

  bool _isInForeground = true;

  Map<String, StreamController<Crypto?>> cryptoController = {};

  Timer? retryConnectionTimer;

  Map<String, String> previousCurrencies = {};

  Map<String, String> lastCurrencies = {};

  Map<String,ValueNotifier<Crypto?>> streamsNotifiers = {};

  final ValueNotifier<int> cryptoListLength = ValueNotifier<int>(0);

  final ValueNotifier<Map<String, int>> orderListener = ValueNotifier<Map<String, int>>({});

  final ValueNotifier<Orientation> orientationUI = ValueNotifier<Orientation>(Orientation.portrait);

  final ValueNotifier<bool> isEditingMode = ValueNotifier<bool>(false);

  Tween<double> _rotationTween = Tween(begin: 360, end: 0);

  late Animation<double> animation;
  late Animation<Color?> animation1;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);

    _initRates();
    _initCryptoWebSocket();

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
              ValueListenableBuilder<bool>(
                  valueListenable: isEditingMode,
                  builder: (_, mode,__) {
                    return ValueListenableBuilder<int>(
                        valueListenable: cryptoListLength,
                        builder: (_, length,__) {
                          var text;
                          if(length == 0) {
                            text = 'add';
                          } else {
                            if(mode) {
                              text = 'Done';
                            } else {
                              text = 'Edit';
                            }
                          }
                          var onPressed = () async {
                            if(length == 0) {
                              await Navigator.push(context, MaterialPageRoute(builder: (context) =>
                                  MultiBlocProvider(
                                    providers: [
                                      BlocProvider(create: (BuildContext context) => CurrenciesBloc(currencyRepo: CurrencyProvider()),),
                                      BlocProvider.value(value: BlocProvider.of<LocalDataBloc>(context),)
                                      // BlocProvider(create: (BuildContext context) => LocalDataBloc.getInstance(),),
                                    ],
                                    child: AddTickerScreen(),)
                              ));
                            } else {
                              isEditingMode.value = !mode;
                            }
                          };
                          return TextButton(
                            onPressed: onPressed,
                            child: Text(text,
                              style: TextStyle(color: Colors.blue[400]),),
                          );
                      });

                  }),
            ],
          ),
        ),
        body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: _body()
        ),
    );
  }

  Widget _body() {
      return OrientationBuilder(
        builder: (_, orientation) {
          orientationUI.value = orientation;
          return Column(
            children: [
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
                  return Container();
                }, buildWhen: (state1, state2) => state2 is CryptoModal || state2 is CryptoEmptyState || state2 is CryptoClosingState,
              ),
              Expanded(
                child: BlocBuilder<CurrenciesBloc, CurrenciesState>(builder: (BuildContext context, CurrenciesState state) {

                  if(state is CurrenciesLoaded) {
                    controller.duration = Duration(milliseconds: (state.currencies.delay * 1000).toInt());
                  }
                  return _bodyUI();
                }, buildWhen: (state1, state2) {
                  return !(state1 is LocalCurrenciesLoaded && state2 is LocalCurrenciesLoaded)  && state2 is! CurrenciesLoading;
                }),
              ),
              _footerUI()
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

      if(state is CryptoError) {
        return Container();
      }
      if(state is CryptoLoading) {
        if(firstLaunch) {
          return Loader(styles: PortraitStyles(),);
        } else {
          if(streamsNotifiers.isEmpty) {
            streamsNotifiers = cryptoController.map((key, value) {
              if(lastCurrencies[key] == null) {
                lastCurrencies[key] = '0.0';
              }
              return MapEntry(key, ValueNotifier(Crypto(price: lastCurrencies[key]!, name: key, queryName: key, )));
            });
          }

          return _cryptoLoaded(cryptoController);
        }
      }
      if(state is LocalCryptoLoaded) {
        retryConnectionTimer = Timer(Duration(seconds: 2), () {
          context.read<CryptoBloc>().add(RetryConnection());
        });

        // return _localCryptoLoaded(state.currencies);
      }
      if(state is CryptoLoaded) {
        print(streamsNotifiers.length);
        if(streamsNotifiers.keys.length != state.streamControllers.keys.length) {
          streamsNotifiers = state.streamControllers.map((key, value) {
            return MapEntry(key, ValueNotifier<Crypto?>(null));
          });
        }
        Future.delayed(Duration.zero, () {
          cryptoListLength.value = state.streamControllers.keys.length;
        });
        streamsNotifiers.forEach((key, value) {
          orderListener.value[key] = streamsNotifiers.keys.toList().indexOf(key);
        });
        // final newObj = {};
        // streamsNotifiers.forEach((key, value) {
        //   newObj[key] = streamsNotifiers.keys.toList().indexOf(key);
        //   orderListener.value[key] = streamsNotifiers.keys.toList().indexOf(key);
        // });
        return _cryptoLoaded(state.streamControllers);
      }
      if(state is CryptoEmpty) {
        return _banner();
      }
      return Container();
    }, buildWhen: (_,state2) => state2 is! CryptoEmptyState && state2 is! CryptoModal && state2 is! CryptoClosingState,);

  }

  Widget _footerUI() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ValueListenableBuilder<bool>(
            valueListenable: isEditingMode,
            builder: (_, mode, __) {
                return ValueListenableBuilder<int>(
                    valueListenable: cryptoListLength,
                    builder: (_, length,__) {
                      if(mode && length > 0) {
                        return TextButton(
                            onPressed: () async {
                              isEditingMode.value = false;
                              await Navigator.push(context, MaterialPageRoute(builder: (context) =>
                                  MultiBlocProvider(
                                    providers: [
                                      BlocProvider(create: (BuildContext context) => CurrenciesBloc(currencyRepo: CurrencyProvider()),),
                                      BlocProvider.value(value: BlocProvider.of<LocalDataBloc>(context),)
                                      // BlocProvider(create: (BuildContext context) => LocalDataBloc.getInstance(),),
                                    ],
                                    child: AddTickerScreen(),)
                              ));
                            },
                            child: Padding(
                              padding: EdgeInsets.only(left: 14.0, right: MediaQuery.of(context).orientation == Orientation.portrait ? 8 : 36),
                              child: Text('Add ticker', style: TextStyle(color: Colors.blue[400]),),
                            ),
                          );
                      }
                      return Container();
                    });
            }),
      ),
    );
  }

  Widget Function(CurrencyStyles styles)
   _orientatedCurrencyWidget({required Crypto crypto}) {
    return (CurrencyStyles styles) {
      return _listenableCurrencyWidget(styles: styles, crypto: crypto);
    };
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

  Widget _wrapItems(Map<String, Widget> renderItems, Map<String, int> order) {
    if(order.length == 0) {
      return _banner();
    }
    return ReorderableListView(
        buildDefaultDragHandles: false,
        shrinkWrap: true,
        children: order.keys.toList().map((key) {
          final item = Slidable(
            key: ValueKey(order[key]), // A key is necessary.

            endActionPane: ActionPane(
              extentRatio: 0.3,
              motion: BehindMotion(),
              dismissible: DismissiblePane(
                onDismissed: () {
                  _removePair(key);
                },
              ),
              children: [
                SlidableAction(
                  onPressed: (s) {
                    _removePair(key);
                  },
                  backgroundColor: Color(0xFFFE4A49),
                  label: 'Remove',
                ),

              ],
            ),
            child: renderItems[key] == null ? Container() : renderItems[key]!,

          );
          return item;
        }).toList(),

        onReorder: (oldIdx, newIdx) {
          if(newIdx > oldIdx) newIdx -= 1;
          final old = orderListener.value;
          final List<MapEntry<String, int>> list = [];
          old.forEach((k,v) => list.add(MapEntry(k,v)));
          final item = list.removeAt(oldIdx);
          list.insert(newIdx, MapEntry(item.key, item.value));
          final Map<String, int> newObj = {};
          newObj.addEntries(list);
          orderListener.value = {...newObj};
          context.read<CryptoBloc>().add(ReorderPair(newIdx: newIdx, pair: cryptoController.keys.toList()[oldIdx]));
        },
    );
  }

  void _removePair(String pair) {
    final Map<String, int> newObj = {};
    orderListener.value.forEach((key1, value) {
      if(key1 != pair) {
        newObj[key1] = value;
      }
    });

    orderListener.value = newObj;
    cryptoListLength.value = newObj.keys.toList().length;
    if(cryptoController[pair] != null) {
      cryptoController[pair]!.close();
    }
    context.read<CryptoBloc>().add(ConfirmedRemovePair(pair: pair));
    streamsNotifiers.remove(pair);
    lastCurrencies.remove(pair);
    previousCurrencies.remove(pair);

  }

  Widget _cryptoLoaded(Map<String, StreamController<Crypto?>> streamControllers) {
    //marker
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
              if(!firstLaunch) {
                var key = streamControllers.keys.firstWhere(
                        (k) => streamControllers[k] == e, orElse:  () => 'null');
                if(key == 'null') {
                  return Container();
                }
                if(lastCurrencies[key] == '0.0') {
                  Future.delayed(Duration.zero, () {
                    if(streamsNotifiers[key] != null) {
                      streamsNotifiers[key]!.value = null;
                    }
                  });
                }
                return Container();
              }
              return Container();
            }
            final crypto = snapshot.data!;
            final graphPrice = GraphicPrice(time: DateTime.now(), open: crypto.price, close: crypto.price);
            if(!crypto.price.startsWith('0.00')) {
              if(chartData.containsKey(crypto.name)) {
                chartData[crypto.name]!.add(graphPrice);
              } else {
                chartData[crypto.name] = [graphPrice];
              }
            } else {
              chartData[crypto.name] = [];
            }
            if(!previousCurrencies.containsKey(crypto.name)
                || (previousCurrencies.containsKey(crypto.name) && previousCurrencies[crypto.name] == null)) {
              previousCurrencies[crypto.name] = crypto.price;
            }
            Future.delayed(Duration.zero, () {
              if(streamsNotifiers[crypto.name] != null) {
                streamsNotifiers[crypto.name]!.value = crypto;
              }
            });
            return Container();
      });
    }).toList();
    final renderItems = streamControllers.map((key, value) {
      return MapEntry(
          key,
          streamsNotifiers[key] != null ?
          Column(
            children: [
              Divider(height: 0,),
              ValueListenableBuilder<Crypto?>(
                  valueListenable: streamsNotifiers[key]!,
                  builder: (_, crypto, __) {
                    if(crypto == null) {
                      return _loaderWrapper(key);
                    }
                    return _orientatedCurrencyWidget(crypto: crypto)(PortraitStyles());
                  }),
            ],
          )
              : Container()
      );
    });
    return SingleChildScrollView(
      child: Column(
        children: [
          ValueListenableBuilder<Map<String, int>>(
              valueListenable: orderListener,
              builder: (_, order, __) {
                return _wrapItems(renderItems, order);
              }),
          Column(
            children: items,
          )
        ],
      ),
    );
  }

  Widget _loaderWrapper(String cryptoName) {
    return ValueListenableBuilder<bool>(
        valueListenable: isEditingMode,
        builder: (_, mode, __) {
          return CryptoLoader(
            styles: PortraitStyles(),
            onDeletePress: _onDeletePair,
            isEditingMode: mode,
            cryptoName: cryptoName,
            index: orderListener.value.keys.toList().indexOf(cryptoName),
          );
        });
  }

  void _onDeletePair(String name) {
    _removePair(name);
  }

  Widget _listenableCurrencyWidget({required CurrencyStyles styles, required Crypto crypto}) {
    final navigate = () {
      final child = cryptoController[crypto.name] == null ? Container() : CurrencyGraphic(crypto: crypto, streamController: cryptoController[crypto.name]!,);
      return Navigator.push(context, MaterialPageRoute(
          builder: (_) => BlocProvider(
        create: (BuildContext context) => CurrenciesBloc(currencyRepo: CurrencyProvider()),
        child: child,
      )));
    };
    return InkWell(
      onTap: navigate,
      child: Column(
        children: [
          // if(cryptoController.keys.toList()[0] != crypto.name)
            // Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ValueListenableBuilder<bool>(
              valueListenable: isEditingMode,
              builder: (_, mode, __) {
                if(mode) return IconButton(
                    padding: EdgeInsets.only(left: 8),
                    constraints: BoxConstraints(),
                    splashRadius: 5,
                    onPressed: () => _onDeletePair(crypto.name),
                    icon: Icon(Icons.remove_circle_sharp, color: Colors.red,));
                return Container();
              }),

              Expanded(
                child: CurrencyWidget(
                  onGraphicPressed: navigate,
                  oldPrice: previousCurrencies[crypto.name] == null ? lastCurrencies[crypto.name]! : previousCurrencies[crypto.name]!,
                  percent: crypto.changePercent,
                  styles: styles,
                  currencyPrice: crypto.price,
                  currencyName: crypto.name,
                ),
              ),
              ValueListenableBuilder<bool>(
                  valueListenable: isEditingMode,
                  builder: (_, mode, __) {
                    if(mode) return ReorderableDragStartListener(
                        index: orderListener.value.keys.toList().indexOf(crypto.name),
                        child: IconButton(
                            splashRadius: 20,
                            onPressed: () {},
                            icon: Icon(Icons.format_align_justify_outlined )
                        )
                    );
                    return Container();
                  }),
            ],
          ),
          // if(cryptoController.keys.toList()[cryptoController.keys.toList().length - 1] != crypto.name)
          //   Divider(),
        ],
      ),
    );

  }

  // Widget _localCryptoLoaded(Map<String, Crypto?> currencies) {
  //   final items = currencies.values.map((crypto) {
  //     if(crypto == null) {
  //       return null;
  //     }
  //     return _orientatedCurrencyWidget(crypto: crypto);
  //   }).toList();
  //
  //
  //   return ValueListenableBuilder<Orientation>(
  //       valueListenable: orientationUI,
  //       builder: (_, orientation, __) {
  //         final styles = orientation == Orientation.portrait ? PortraitStyles() : LandscapeStyles();
  //         final styledItems = items.where((element) => element!=null).map<Widget>((e) {
  //           return e!(styles);
  //         }).toList();
  //         if(orientation == Orientation.portrait) {
  //           return ValueListenableBuilder<bool>(
  //               valueListenable: isEditingMode,
  //               builder: (_, mode, __) {
  //                 if(mode) {
  //
  //                   final wrap = ReorderableWrap(
  //                     onReorder: (oldIdx, newIdx) {
  //                       final pair = currencies.keys.toList()[oldIdx];
  //                       context.read<CryptoBloc>().add(LocalReorderPair(newIdx: newIdx, pair: pair));
  //                     },
  //                     children: styledItems,
  //                   );
  //                   return SingleChildScrollView(child: wrap,);
  //                 }
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
  //             // key = UniqueKey();
  //           }
  //           return SizedBox(
  //             width: MediaQuery.of(context).size.width,
  //             height: MediaQuery.of(context).size.height - (LayoutStyles.appbarHeight + LayoutStyles.footerHeight),
  //             child: Swiper(
  //                 pagination: const SwiperPagination(
  //                   alignment: Alignment.bottomCenter,
  //                   builder: DotSwiperPaginationBuilder(
  //                     color: Colors.grey,
  //                   ),
  //                 ),
  //                 itemCount: styledItems.length,
  //                 itemBuilder: (BuildContext context, int index) => styledItems[index])
  //           );
  //         }
  //           return Container();
  //     },
  //   );
  // }

  @override
  void dispose() {
    if(retryConnectionTimer != null) retryConnectionTimer!.cancel();
    controller.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    firstLaunch = false;
    print(state);
    if(state == AppLifecycleState.resumed) {
      print('connection resumed');

      context.read<CryptoBloc>().add(CryptoInitConnection());
      _isInForeground = true;
    } else {
      isEditingMode.value = false;
      if(_isInForeground) {
        lastCurrencies = Map.from(previousCurrencies);
        previousCurrencies = {};
        print('connection dead');
        chartData.keys.toList().forEach((element) {
          chartData[element] = [];
        });
        context.read<CryptoBloc>().add(CryptoCloseAllConnections());

        cryptoController.forEach((key, value) {
          value.close();
        });
        _isInForeground = false;
      }
    }
  }

}
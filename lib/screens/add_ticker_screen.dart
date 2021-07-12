// import 'dart:async';
//
// import 'package:connectivity/connectivity.dart';
// import 'package:currencies_pages/bloc/localData/bloc.dart';
// import 'package:currencies_pages/bloc/localData/events.dart';
// import 'package:currencies_pages/bloc/localData/states.dart';
// import 'package:currencies_pages/constants.dart';
// import 'package:currencies_pages/tools.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
// import '../styles.dart';
//
// class AddTickerScreen extends StatefulWidget {
//   const AddTickerScreen({Key? key}) : super(key: key);
//
//   @override
//   _AddTickerScreenState createState() => _AddTickerScreenState();
// }
//
// class _AddTickerScreenState extends State<AddTickerScreen> {
//   Map<Currency_Pairs, bool> pairsAdded = {};
//   bool connected = true;
//   late final StreamSubscription<ConnectivityResult> internetSubscription;
//   @override
//   void initState() {
//     initConnect();
//     super.initState();
//     internetSubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
//       if(result == ConnectivityResult.none) {
//         setState(() {
//           connected = false;
//         });
//       } else {
//         setState(() {
//           connected = true;
//         });
//       }
//       // Got a new connectivity status!
//     });
//     context.read<LocalDataBloc>().add(GetAvailableToAddPairs());
//   }
//   initConnect() async {
//     final isDeviceConnectedToInternet = await Connectivity().checkConnectivity() != ConnectivityResult.none;
//     setState(() {
//       connected = isDeviceConnectedToInternet;
//     });
//   }
//   @override
//   void dispose() {
//     internetSubscription.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: PreferredSize(child: AppBar(title: Text('Add Tickers'),), preferredSize: Size.fromHeight(LayoutStyles.appbarHeight)),
//         body: OrientationBuilder(builder: (_, orientation) {
//           return Padding(
//             padding: orientation == Orientation.landscape ? EdgeInsets.only(right: 24) : EdgeInsets.zero,
//             child: _body(),
//           );
//         })
//     );
//   }
//
//   Widget _body() {
//     return BlocBuilder<LocalDataBloc, LocalDataState>(builder: (BuildContext context, LocalDataState state) {
//       print(state);
//       if(state is AvailableToAddPairs) {
//         final pairs = state.pairs;
//         if(pairsAdded.isEmpty) {
//           pairsAdded = {for (var pair in pairs) pair: false};
//         }
//         return _availablePairsView(pairs);
//       }
//       return Container();
//     }, buildWhen: (state1, state2) {
//       return state2 is AvailableToAddPairs;
//     },);
//   }
//
//   Widget _availablePairsView(List<Currency_Pairs> pairs) {
//     if(pairs.isEmpty) {
//       return Center(child: Text("You've added all available currencies", textAlign: TextAlign.center, style: TextStyle(fontSize: 40),),);
//     }
//     final Color? buttonColor = connected ? null : Colors.grey;
//
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: ListView(
//         children: pairs.map((pair) {
//           return Padding(
//             padding: const EdgeInsets.only(top: 8.0),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 _styledText(CryptoFromBackendHelper.getNameByCurrencyType(pair)),
//                 Spacer(),
//                 Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.all(Radius.circular(10)),
//                     color: buttonColor != null ? buttonColor : !pairsAdded[pair]! ? Colors.blue : Colors.red
//                   ),
//                   child: Center(
//                     child: TextButton(
//                       onPressed: () => connected ? _onPairClick(pair) : null,
//                       child: !pairsAdded[pair]! ? _styledTextButton('Add') : _styledTextButton('undo'),
//                     ),
//                   ),
//                 )
//               ],
//             ),
//           );
//         }).toList(),
//       ),
//     );
//   }
//
//   _onPairClick(Currency_Pairs pair) {
//     if(!pairsAdded[pair]!) { // if it false btn was pressed
//       context.read<LocalDataBloc>().add(AddPair(pair: pair));
//     } else {
//       context.read<LocalDataBloc>().add(RemovePair(pair: pair));
//     }
//     setState(() {
//       pairsAdded[pair] = !pairsAdded[pair]!;
//     });
//   }
//
//   Text _styledText(String text) {
//     return Text(text, style: TextStyle(fontSize: AddTickerStyles.fontSize),);
//   }
//   Text _styledTextButton(String text) {
//     return Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodyText1!.color),);
//   }
// }

import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:currencies_pages/bloc/currency/bloc.dart';
import 'package:currencies_pages/bloc/currency/events.dart';
import 'package:currencies_pages/bloc/currency/states.dart';
import 'package:currencies_pages/model/currencies.dart';
import 'package:currencies_pages/widgets/add_ticker_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:substring_highlight/substring_highlight.dart';

import '../styles.dart';

class AddTickerScreen extends StatefulWidget {
  const AddTickerScreen({Key? key}) : super(key: key);

  @override
  _AddTickerScreenState createState() => _AddTickerScreenState();
}

class _AddTickerScreenState extends State<AddTickerScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  Map<String, bool> pairsAdded = {};
  bool connected = true;

  final ValueNotifier<bool> filterOpened = ValueNotifier<bool>(true);

  String baseInputValue = '';
  String quoteInputValue = '';
  bool baseInputFocused = false;
  bool quoteInputFocused = false;

  late final StreamSubscription<ConnectivityResult> internetSubscription;
  @override
  void initState() {
    _initCurrencies();
    initConnect();
    super.initState();

    internetSubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if(result == ConnectivityResult.none) {
        setState(() {
          connected = false;
        });
      } else {
        setState(() {
          connected = true;
        });
      }
      // Got a new connectivity status!
    });
  }
  initConnect() async {
    final isDeviceConnectedToInternet = await Connectivity().checkConnectivity() != ConnectivityResult.none;
    setState(() {
      connected = isDeviceConnectedToInternet;
    });
  }

  @override
  void dispose() {
    internetSubscription.cancel();
    super.dispose();
  }
  _initCurrencies() {
    context.read<CurrenciesBloc>().add(GetBinance());
  }
  _onBaseFocusChange() {
    setState(() {baseInputFocused = !baseInputFocused;});
  }
  _onQuoteFocusChange() {
    setState(() {quoteInputFocused = !quoteInputFocused;});
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       resizeToAvoidBottomInset: false,
        appBar: PreferredSize(child: AppBar(title: Text('Add Tickers'),), preferredSize: Size.fromHeight(LayoutStyles.appbarHeight)),
        body: OrientationBuilder(builder: (_, orientation) {
          return Padding(
            padding: orientation == Orientation.landscape ? EdgeInsets.only(right: 24) : EdgeInsets.zero,
            child: _body(),
          );
        })
    );
  }

  Widget _body() {
    return Column(
      children: [
        _filter(),
        Expanded(
          child: BlocBuilder<CurrenciesBloc, CurrenciesState>(builder: (BuildContext context, CurrenciesState state) {
            print(state);
            if(state is CurrenciesLoaded) {
              if(pairsAdded.isEmpty) {
                pairsAdded = {for (var currency in state.currencies.currencies) currency.type: false};
              }
              return _bodyUI(currencies: state.currencies);
            }
            if(state is LocalCurrenciesLoaded) {
              if(pairsAdded.isEmpty) {
                pairsAdded = {for (var currency in state.currencies.currencies) currency.type: false};
              }

              return _bodyUI(currencies: state.currencies);
            }
            if(state is CurrenciesLoading) {
              if(baseInputValue.isEmpty && quoteInputValue.isEmpty) {
                return _typeToSeeTip();
              } else {
                return Center(child: CircularProgressIndicator(),);
              }
            }
            return Text('');
          }),
        )
      ],
    );
  }
  void _onArrowTap() {
    filterOpened.value = !filterOpened.value;
  }
  Widget _filter() {
    return ValueListenableBuilder<bool>(
        valueListenable: filterOpened,
        builder: (context, bool filterOpened, child){
          return AnimatedSize(
              curve: Curves.fastOutSlowIn,
              duration: Duration(milliseconds: 300),
              vsync: this,
              child: Column(
                children: [
                  SizedBox(
                    height: filterOpened ? null : 0,
                    child: Column(
                      children: [
                        _baseTextField(),
                        _quoteTextField()
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _onArrowTap,
                    child: Center(
                        child: filterOpened ? Icon(Icons.arrow_circle_up_outlined) : Icon(Icons.arrow_drop_down)
                    ),
                  )
                ],
              )
          );
        }
    );
  }

  Widget _bodyUI({required BinanceRestCurrencies currencies}) {
    return _availablePairsView(currencies.currencies);
  }

  Widget _availablePairsView(List<Currency> pairs) {
    final Color? buttonColor = connected ? null : Colors.grey;

    final filteredPairs = pairs.where((currency) =>
        currency.baseAsset.toLowerCase().startsWith(baseInputValue.toLowerCase())
        && currency.quoteAsset.toLowerCase().startsWith(quoteInputValue.toLowerCase())
    ).toList();

    if(baseInputValue.isEmpty && quoteInputValue.isEmpty) {
      return _typeToSeeTip();
    }
    if(filteredPairs.isEmpty) {
      return _emptyListTip();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: filteredPairs.length,
        itemBuilder: (_, index) {
          final pair = filteredPairs[index];
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _styledText(pair),
                Spacer(),
                Container(
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      color: buttonColor != null ? buttonColor : !pairsAdded[pair.type]! ? Colors.blue : Colors.red
                  ),
                  child: Center(
                    child: TextButton(
                      onPressed: () => connected ? _onPairClick(pair.type) : null,
                      child: !pairsAdded[pair.type]! ? _styledTextButton('Add') : _styledTextButton('undo'),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  _onPairClick(String pair) {
    if(!pairsAdded[pair]!) { // if it false btn was pressed
      // context.read<LocalDataBloc>().add(AddPair(pair: pair));
    } else {
      // context.read<LocalDataBloc>().add(RemovePair(pair: pair));
    }
    setState(() {
      pairsAdded[pair] = !pairsAdded[pair]!;
    });
  }

  Widget _styledText(Currency currency) {
    return Row(
      children: [
        _highLight(currency.baseAsset, baseInputValue),
        Text('-', style: TextStyle(fontSize: AddTickerStyles.fontSize)),
        _highLight(currency.quoteAsset, quoteInputValue)
      ],
    );
  }

  Widget _highLight(String text, String inputValue) {
    return SubstringHighlight(
      text: text,
      term: inputValue,
      textStyle: TextStyle(fontSize: AddTickerStyles.fontSize, color: Theme.of(context).textTheme.bodyText1!.color),
      textStyleHighlight: TextStyle(fontSize: AddTickerStyles.fontSize, color: Colors.yellow),
    );
  }

  Widget _styledTextButton(String text) {
    return Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodyText1!.color),);
  }

  Widget _baseTextField() {
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return KeyboardVisibilityBuilder(
        builder: (_, isOpened) {
          if(!isOpened || isPortrait) {
            return __baseTextField();
          }
          if(isOpened && baseInputFocused) {
            return __baseTextField();
          }
          return Container();
        }
    );
  }
  Widget __baseTextField() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: MyTextField(labelText: 'Base asset', onChange: _onBaseInputChange, onFocusChange: _onBaseFocusChange),
    );
  }
  Widget _quoteTextField() {
    var isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return KeyboardVisibilityBuilder(
        builder: (_, isOpened) {
          if(!isOpened || isPortrait) {
            return __quoteTextField();
          }
          if(isOpened && quoteInputFocused) {
            return __quoteTextField();
          }
          return Container();
        }
    );
  }
  Widget __quoteTextField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: MyTextField(labelText: 'Quote asset', onChange: _onQuoteInputChange, onFocusChange: _onQuoteFocusChange),
    );
  }

  void _onBaseInputChange(String text) {
    setState(() {
      baseInputValue = text;
    });
  }
  void _onQuoteInputChange(String text) {
    setState(() {
      quoteInputValue = text;
    });
  }

  Widget _typeToSeeTip() {
    return Align(
        alignment: Alignment.topCenter,
        child: Text('Type and choose the one you need.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: AddTickerStyles.fontSize),
        )
    );
  }

  Widget _emptyListTip() {
    return Align(
        alignment: Alignment.topCenter,
        child: Text('There is no one symbol relevant to your filter.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: AddTickerStyles.fontSize),
        )
    );
  }
}

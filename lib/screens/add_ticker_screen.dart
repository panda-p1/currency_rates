import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:currencies_pages/bloc/localData/bloc.dart';
import 'package:currencies_pages/bloc/localData/events.dart';
import 'package:currencies_pages/bloc/localData/states.dart';
import 'package:currencies_pages/constants.dart';
import 'package:currencies_pages/tools.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/src/provider.dart';

import '../styles.dart';

class AddTickerScreen extends StatefulWidget {
  const AddTickerScreen({Key? key}) : super(key: key);

  @override
  _AddTickerScreenState createState() => _AddTickerScreenState();
}

class _AddTickerScreenState extends State<AddTickerScreen> {
  Map<Currency_Pairs, bool> pairsAdded = {};
  bool connected = true;
  late final StreamSubscription<ConnectivityResult> internetSubscription;
  @override
  void initState() {
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
    context.read<LocalDataBloc>().add(GetAvailableToAddPairs());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    return BlocBuilder<LocalDataBloc, LocalDataState>(builder: (BuildContext context, LocalDataState state) {
      print(state);
      if(state is AvailableToAddPairs) {
        final pairs = state.pairs;
        if(pairsAdded.isEmpty) {
          pairsAdded = {for (var pair in pairs) pair: false};
        }
        return _availablePairsView(pairs);
      }
      return Container();
    }, buildWhen: (state1, state2) {
      return state2 is AvailableToAddPairs;
    },);
  }

  Widget _availablePairsView(List<Currency_Pairs> pairs) {
    if(pairs.isEmpty) {
      return Center(child: Text("You've added all available currencies", textAlign: TextAlign.center, style: TextStyle(fontSize: 40),),);
    }
    final Color? buttonColor = connected ? null : Colors.grey;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: pairs.map((pair) {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _styledText(CryptoFromBackendHelper.getNameByCurrencyType(pair)),
                Spacer(),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: buttonColor != null ? buttonColor : !pairsAdded[pair]! ? Colors.blue : Colors.red
                  ),
                  child: Center(
                    child: TextButton(
                      onPressed: () => connected ? _onPairClick(pair) : null,
                      child: !pairsAdded[pair]! ? _styledTextButton('Add') : _styledTextButton('undo'),
                    ),
                  ),
                )
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  _onPairClick(Currency_Pairs pair) {
    if(!pairsAdded[pair]!) { // if it false btn was pressed
      context.read<LocalDataBloc>().add(AddPair(pair: pair));
    } else {
      context.read<LocalDataBloc>().add(RemovePair(pair: pair));
    }
    setState(() {
      pairsAdded[pair] = !pairsAdded[pair]!;
    });
  }

  Text _styledText(String text) {
    return Text(text, style: TextStyle(fontSize: AddTickerStyles.fontSize),);
  }
  Text _styledTextButton(String text) {
    return Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodyText1!.color),);
  }
}

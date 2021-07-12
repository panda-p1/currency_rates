import 'package:currencies_pages/bloc/localData/bloc.dart';
import 'package:currencies_pages/bloc/localData/events.dart';
import 'package:currencies_pages/bloc/localData/states.dart';
import 'package:currencies_pages/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:currencies_pages/bloc/currency/bloc.dart';

import 'api/currenciesProvider.dart';
import 'bloc/crypto/bloc.dart';
  
void main() {
  runApp(BlocProvider(
      create: (BuildContext context) => LocalDataBloc.getInstance(),
      child: MyApp()
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    context.read<LocalDataBloc>().add(GetTheme());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalDataBloc, LocalDataState>(builder: (context, LocalDataState state) {
      if(state is ThemeLoaded) {
        return _buildWithTheme(context, state.theme);
      }
      return Container();
    });
  }

  Widget _buildWithTheme(BuildContext context, ThemeData theme) {
      return MaterialApp(
        title: 'Flutter Demo',
        theme: theme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider(create: (BuildContext context) => CurrenciesBloc(currencyRepo: CurrencyProvider()),),
            BlocProvider(create: (BuildContext context) => LocalDataBloc.getInstance(),),
            BlocProvider(create: (BuildContext context) => CryptoBloc(),),
          ],
          child: HomeScreen(),
        )
      );
  }
}

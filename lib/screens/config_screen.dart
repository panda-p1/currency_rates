import 'package:currencies_pages/api/services.dart';
import 'package:currencies_pages/bloc/currency/bloc.dart';
import 'package:currencies_pages/bloc/localData/bloc.dart';
import 'package:currencies_pages/bloc/localData/events.dart';
import 'package:currencies_pages/bloc/localData/states.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../styles.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({Key? key}) : super(key: key);

  @override
  _ConfigScreenState createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  bool switched = false;
  double delay1 = 1;
  @override
  void initState() {
    _loadData();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, delay1);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(),
        body: OrientationBuilder(builder: (_, orientation) {
          return Padding(
            padding: orientation == Orientation.landscape ? EdgeInsets.only(right: 24) : EdgeInsets.zero,
            child: _body(),
          );
        })
      ),
    );
  }
  void _loadData() {
    context.read<LocalDataBloc>().add(GetDelay());
    context.read<LocalDataBloc>().add(GetTheme());
  }
  Widget _body() {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              _styledText('Theme'),
              Spacer(),
              BlocBuilder<LocalDataBloc, LocalDataState>(builder: (BuildContext context, LocalDataState state) {
                if(state is ThemeLoaded) {
                  return Switch(value: state.theme != lightTheme, onChanged: (b) {
                    context.read<LocalDataBloc>().add(ChangeTheme());
                  });
                }
                return Container();
              }, buildWhen: (state1, state2) {
                return state2 is ThemeLoaded;
              },)
            ],
          ),
          BlocBuilder<LocalDataBloc, LocalDataState>(builder: (BuildContext context, LocalDataState state) {
            if(state is DelayLoaded) {
              delay1 = state.delay;
            }
            return Row(
              children: [
                _styledText('Delay'),
                Spacer(),
                state is DelayLoaded

                    ? IconButton(
                    splashRadius: ConfigStyles.arrowSplashRadius,
                    onPressed: () {
                      if(state.delay > 4) {
                        context.read<LocalDataBloc>().add(DecreaseDelay());
                        context.read<LocalDataBloc>().add(GetTheme());
                      }
                    }, icon: _styledIcon(Icons.arrow_left_outlined, color: state.delay <= 4 ? Colors.grey : null,))

                    : IconButton(splashRadius: ConfigStyles.arrowSplashRadius, onPressed: () {}, icon: _styledIcon(Icons.arrow_left_outlined),),

                state is DelayLoaded
                    ? _styledText(state.delay.toString())
                    : _styledText('...'),

                IconButton(
                    splashRadius: ConfigStyles.arrowSplashRadius,
                    onPressed: () {
                      context.read<LocalDataBloc>().add(IncreaseDelay());
                      context.read<LocalDataBloc>().add(GetTheme());

                    },
                    icon: _styledIcon(Icons.arrow_right_outlined)),
              ],
            );
          }, buildWhen: (state1, state2) {
            return state2 is DelayLoaded || state2 is DelayLoading;
          },)
        ],
      ),
    );
  }

  Text _styledText(String text) {
    return Text(text, style: TextStyle(fontSize: ConfigStyles.fontSize),);
  }

  Icon _styledIcon(IconData icon, {Color? color}) {
    return Icon(icon, color:color, size: ConfigStyles.arrowIconSize,);
  }
}


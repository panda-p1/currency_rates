import 'package:flutter/cupertino.dart';
import '../constants.dart';

class ScrollNotificationListener extends StatefulWidget {
  final Widget child;
  final Function setLoadingTrue;
  final Function stopController;
  const ScrollNotificationListener({Key? key, required this.child, required this.stopController, required this.setLoadingTrue}) : super(key: key);

  @override
  _ScrollNotificationListenerState createState() => _ScrollNotificationListenerState();
}

class _ScrollNotificationListenerState extends State<ScrollNotificationListener> {
  ScrollController _scrollController = ScrollController();
  bool dropped = false;
  double yScrollPosition = 0;
  double _signalHeight = heightForSignal;

  @override
  void initState() {
    _scrollController.addListener(() {
      if(_scrollController.hasClients) {
        Future.delayed(Duration.zero,() {if(_scrollController.position.pixels <= 0 && !dropped) {
          yScrollPosition = - _scrollController.position.pixels;
        }});
      }

    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: _onScroll,
      child: SingleChildScrollView(
          controller: _scrollController,
          physics: BouncingScrollPhysics(),
          child: widget.child
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
          widget.setLoadingTrue();
          Future.delayed(Duration(seconds: 1), () async {
            // context.read<CurrenciesBloc>().add(CurrenciesEvents.getRate);
          });
          widget.stopController();
        }
      }
    }
    return false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

}

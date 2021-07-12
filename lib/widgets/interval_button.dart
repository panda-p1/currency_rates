import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class IntervalButton extends StatelessWidget {
  final String text;
  final Function onClick;
  final bool clicked;
  const IntervalButton({Key? key, required this.clicked, required this.text, required this.onClick}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(clicked ? Colors.black : null)
      ),
      onPressed: () {
        onClick();
      },
      child: Text(text),
    );
  }
}

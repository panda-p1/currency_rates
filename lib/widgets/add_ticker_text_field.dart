import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final String labelText;
  final void Function(String input) onChange;
  final void Function() onFocusChange;
  const MyTextField({Key? key, required this.labelText, required this.onFocusChange, required this.onChange}) : super(key: key);

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    _controller.addListener(() {
      widget.onChange(_controller.text);
    });
    _focusNode.addListener(() {
      widget.onFocusChange();
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: TextField(
            focusNode: _focusNode,
            controller: _controller,
            decoration: new InputDecoration(
              labelText: widget.labelText,
              fillColor: Theme.of(context).textTheme.bodyText1!.color,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.0),
                borderSide: BorderSide(),
              ),
              //fillColor: Colors.green
            ),

            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(
              fontFamily: "Poppins",
            )
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final String labelText;
  final void Function(String input) onChange;
  const MyTextField({Key? key, required this.labelText, required this.onChange}) : super(key: key);

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  final _controller = TextEditingController();
  @override
  void initState() {
    _controller.addListener(() {
      widget.onChange(_controller.text);
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: TextField(
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
            style: new TextStyle(
              fontFamily: "Poppins",
            )
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

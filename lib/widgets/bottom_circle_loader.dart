import 'dart:math';

import 'package:currencies_pages/screens/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../styles.dart';
import '../tools.dart';

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
          2 * pi- 0.001, // 7.
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

    canvas.drawPath(path1, paint1);   // 8.

    canvas.drawPath(path, paint);   // 8.
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // bad, but okay for example
    return true;
  }
}

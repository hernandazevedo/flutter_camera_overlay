import 'package:flutter/material.dart';

class SquarePainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.teal
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
      // ..strokeCap = StrokeCap.round;

    // var path = Path();
    var rect = Rect.fromLTRB(20, 20, 20, 20);
    // path.addOval();
    // canvas.drawPath(path, paint);
    // canvas.drawRect(rect, paint);
    canvas.drawRect(rect, paint);

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

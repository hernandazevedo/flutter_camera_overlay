import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'coordinates_translator.dart';

class ObjectDetectorPainter extends CustomPainter {
  ObjectDetectorPainter(
    this._objects,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
    this.onDocumentDetected, 
    this.desiredSquareRect
  );
  final Function()? onDocumentDetected;
  Rect? desiredSquareRect;
  final List<DetectedObject> _objects;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 //TODO parametrize this
      ..color = Colors.redAccent; //TODO parametrize this

    // final Paint paintSquare = Paint()
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 3.0
    //   ..color = Colors.red;

    // final left = 200.0;
    // final top = 200.0;
    // final right = 200.0;
    // final bottom = 200.0;

    double width = size.width * .9;
    double x = (size.width * .1) / 2;

    double ratio = 1.42;
    double height = width / ratio;

    desiredSquareRect = (Offset(x, height) & Size(width, height));

    //initial desired position to fit the document
    canvas.drawRect(desiredSquareRect!, paint);

    // final Paint background = Paint()..color = Color(0x99000000);
    // if (desiredSquareRect != null) {
    //   canvas.drawRect(
    //     desiredSquareRect!,
    //     paintSquare,
    //   );
    // }
    for (final DetectedObject detectedObject in _objects) {
      // FIXME Drivers license, understand how to use parameters here
      if(!detectedObject.labels.any((it) => it.text.contains("Driver's license"))) return;

      // final ParagraphBuilder builder = ParagraphBuilder(
      //   ParagraphStyle(
      //       textAlign: TextAlign.left,
      //       fontSize: 16,
      //       textDirection: TextDirection.ltr),
      // );
      // builder.pushStyle(
      //     ui.TextStyle(color: Colors.lightGreenAccent, background: background));
      // if (detectedObject.labels.isNotEmpty) {
      //   final label = detectedObject.labels
      //       .reduce((a, b) => a.confidence > b.confidence ? a : b);
      //   // builder.addText('${label.text} ${label.confidence}\n');
      // }
      // builder.pop();

      const maxDistance = 35.0;

      final left = translateX(
        detectedObject.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        detectedObject.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        detectedObject.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        detectedObject.boundingBox.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final objectRect = Rect.fromLTRB(left, top, right, bottom);
      if (desiredSquareRect != null) {
        if(
        (desiredSquareRect!.top - objectRect.top).abs() < maxDistance &&
        (desiredSquareRect!.left - objectRect.left).abs() < maxDistance &&
        (desiredSquareRect!.right - objectRect.right).abs() < maxDistance &&
        (desiredSquareRect!.bottom - objectRect.bottom).abs() < maxDistance
        ){
          onDocumentDetected?.call();
          //TODO parametrize this
          paint.color = Colors.lightGreenAccent;
        }
      }

      canvas.drawRect(desiredSquareRect!, paint);
      // canvas.drawRect(
      //   objectRect,
      //   paint,
      // );

      // canvas.drawParagraph(
      //   builder.build()
      //     ..layout(ParagraphConstraints(
      //       width: (right - left).abs(),
      //     )),
      //   Offset(
      //       Platform.isAndroid &&
      //               cameraLensDirection == CameraLensDirection.front
      //           ? right
      //           : left,
      //       top),
      // );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'package:flutter/material.dart';
import 'package:flutter_camera_overlay/model.dart';
extension GlobalPaintBounds on BuildContext {
  Rect? get globalPaintBounds {
    final renderObject = findRenderObject();
    final translation = renderObject?.getTransformTo(null).getTranslation();
    if (translation != null && renderObject?.paintBounds != null) {
      final offset = Offset(translation.x, translation.y -70);
      return renderObject!.paintBounds.shift(offset);
    } else {
      return null;
    }
  }
}
class OverlayShape extends StatelessWidget {
  const OverlayShape({Key? key, this.onSquareRect, required this.model}) : super(key: key);

  final OverlayModel model;
  final Function(Rect)? onSquareRect;

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context);
    var size = media.size;
    double width = media.orientation == Orientation.portrait
        ? size.shortestSide * .9
        : size.longestSide * .5;

    double ratio = model.ratio as double;
    double height = width / ratio;
    double radius =
        model.cornerRadius == null ? 0 : model.cornerRadius! * height;



    if (media.orientation == Orientation.portrait) {}
    return Stack(
      children: [
        Align(
            alignment: Alignment.center,
            child: Container(
              width: width,
              height: width / ratio,
              decoration: ShapeDecoration(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(radius),
                      side: const BorderSide(width: 1, color: Colors.white))),
            child: Builder(builder: (BuildContext context) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => onSquareRect?.call(
                  context.globalPaintBounds!
                // Rect.fromCenter(
                // center: Offset(width -165, height +105),
                // // radius: radius
                // width: width, height: height)
              )
              );
              return const SizedBox.shrink();
            },),)),
        ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.black12, BlendMode.srcOut),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: width,
                    height: width / ratio,
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(radius)),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

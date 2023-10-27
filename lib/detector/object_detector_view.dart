import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_camera_overlay/detector/camera_view.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_camera_overlay/model.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'detector_view.dart';
import 'object_detector_painter.dart';
import 'utils.dart';

class ObjectDetectorView extends StatefulWidget {
  final String? label;
  final String? info;
  final EdgeInsets? infoMargin;
  final Function(String)? onDocumentDetected;

  const ObjectDetectorView({Key? key, this.label, this.info, this.infoMargin, this.onDocumentDetected}) : super(key: key);
  @override
  State<ObjectDetectorView> createState() => _ObjectDetectorView();
}

class _ObjectDetectorView extends State<ObjectDetectorView> {
  ObjectDetector? _objectDetector;
  DetectionMode _mode = DetectionMode.stream;
  final PictureController _pictureController = PictureController();
  bool _canProcess = false;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  var _cameraLensDirection = CameraLensDirection.back;
  int _option = 1;
  final _options = {
    'default': '',
    'object_custom': 'object_labeler.tflite',
    'fruits': 'object_labeler_fruits.tflite',
    'flowers': 'object_labeler_flowers.tflite',
    'birds': 'lite-model_aiy_vision_classifier_birds_V1_3.tflite',
    // https://tfhub.dev/google/lite-model/aiy/vision/classifier/birds_V1/3

    'food': 'lite-model_aiy_vision_classifier_food_V1_1.tflite',
    // https://tfhub.dev/google/lite-model/aiy/vision/classifier/food_V1/1

    'plants': 'lite-model_aiy_vision_classifier_plants_V1_3.tflite',
    // https://tfhub.dev/google/lite-model/aiy/vision/classifier/plants_V1/3

    'mushrooms': 'lite-model_models_mushroom-identification_v1_1.tflite',
    // https://tfhub.dev/bohemian-visual-recognition-alliance/lite-model/models/mushroom-identification_v1/1

    'landmarks':
        'lite-model_on_device_vision_classifier_landmarks_classifier_north_america_V1_1.tflite',
    // https://tfhub.dev/google/lite-model/on_device_vision/classifier/landmarks_classifier_north_america_V1/1
  };

  @override
  void dispose() {
    _canProcess = false;
    _objectDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        DetectorView(
            pictureController: _pictureController,
            title: 'Object Detector',
            customPaint: _customPaint,
            text: _text,
            onImage: (InputImage inputImage) {
              _processImage(inputImage, widget.onDocumentDetected);
            },
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
            onCameraFeedReady: _initializeDetector,
            initialDetectionMode: DetectorViewMode.values[_mode.index],
            onDetectorViewModeChanged: _onScreenModeChanged,
          ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
              margin: widget.infoMargin ??
                  const EdgeInsets.only(top: 100, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.label != null)
                    Text(
                      widget.label!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
                  if (widget.info != null)
                    Flexible(
                      child: Text(
                        widget.info!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              )),
        )
        // Positioned(
        //     top: 30,
        //     left: 100,
        //     right: 100,
        //     child: Row(
        //       children: [
        //         Spacer(),
        //         Container(
        //             decoration: BoxDecoration(
        //               color: Colors.black54,
        //               borderRadius: BorderRadius.circular(10.0),
        //             ),
        //             child: Padding(
        //               padding: const EdgeInsets.all(4.0),
        //               child: _buildDropdown(),
        //             )),
        //         Spacer(),
        //       ],
        //     ))
        // ,
      ]),
    );
  }

  Widget _buildDropdown() => DropdownButton<int>(
        value: _option,
        icon: const Icon(Icons.arrow_downward),
        elevation: 16,
        style: const TextStyle(color: Colors.blue),
        underline: Container(
          height: 2,
          color: Colors.blue,
        ),
        onChanged: (int? option) {
          if (option != null) {
            setState(() {
              _option = option;
              _initializeDetector();
            });
          }
        },
        items: List<int>.generate(_options.length, (i) => i)
            .map<DropdownMenuItem<int>>((option) {
          return DropdownMenuItem<int>(
            value: option,
            child: Text(_options.keys.toList()[option]),
          );
        }).toList(),
      );

  void _onScreenModeChanged(DetectorViewMode mode) {
    switch (mode) {
      // case DetectorViewMode.gallery:
      //   _mode = DetectionMode.single;
      //   _initializeDetector();
      //   return;

      case DetectorViewMode.liveFeed:
        _mode = DetectionMode.stream;
        _initializeDetector();
        return;
    }
  }

  void _initializeDetector() async {
    _objectDetector?.close();
    _objectDetector = null;
    print('Set detector in mode: $_mode');

    if (_option == 0) {
      // use the default model
      print('use the default model');
      final options = ObjectDetectorOptions(
        mode: _mode,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = ObjectDetector(options: options);
    } else if (_option > 0 && _option <= _options.length) {
      // use a custom model
      // make sure to add tflite model to assets/ml
      final option = _options[_options.keys.toList()[_option]] ?? '';
      final modelPath = await getAssetPath('assets/ml/$option');
      print('use custom model path: $modelPath');
      final options = LocalObjectDetectorOptions(
        mode: _mode,
        modelPath: modelPath,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = ObjectDetector(options: options);
    }

    // uncomment next lines if you want to use a remote model
    // make sure to add model to firebase
    // final modelName = 'bird-classifier';
    // final response =
    //     await FirebaseObjectDetectorModelManager().downloadModel(modelName);
    // print('Downloaded: $response');
    // final options = FirebaseObjectDetectorOptions(
    //   mode: _mode,
    //   modelName: modelName,
    //   classifyObjects: true,
    //   multipleObjects: true,
    // );
    // _objectDetector = ObjectDetector(options: options);

    _canProcess = true;
  }

  Future<void> _processImage(InputImage inputImage, Function(String)? onDocumentDetected) async {
    if (_objectDetector == null) return;
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final objects = await _objectDetector!.processImage(inputImage);
    // print('Objects found: ${objects.length}\n\n');
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {

      // final image = img.Image.fromBytes(
      //     width: inputImage.metadata!.size.width.toInt(), height: inputImage.metadata!.size.height.toInt(), bytes: inputImage.bytes!.buffer);

      final painter = ObjectDetectorPainter(
        objects,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
        () {
          WidgetsBinding.instance
                    .addPostFrameCallback((_) => setState(() {
            _canProcess = false;
            buildDialogWithImage(onDocumentDetected);
          }));

          },

      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      String text = 'Objects found: ${objects.length}\n\n';
      for (final object in objects) {
        text +=
            'Object:  trackingId: ${object.trackingId} - ${object.labels.map((e) => e.text)}\n\n';
      }
      _text = text;
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  void buildDialogWithImage(Function(String)? onDocumentDetected) async {
    final picture = await _pictureController.takePicture();
    final imagePath = picture.path;
    return showDialog(
            context: context,
            barrierColor: Colors.black,
            builder: (context) {
              return AlertDialog(
                  actionsAlignment: MainAxisAlignment.center,
                  backgroundColor: Colors.black,
                  title: const Text('Capturar',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center),
                  actions: [
                    OutlinedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          setState(() {
                            _canProcess = true;
                          });
                        },
                        child: const Icon(Icons.close)),
                    OutlinedButton(
                        onPressed: () async {
                          onDocumentDetected?.call(imagePath);
                          Navigator.of(context).pop();
                          setState(() {
                            _canProcess = true;
                          });
                        },
                        child: const Icon(Icons.check))
                  ],
                  content: SizedBox(
                      width: double.infinity,
                      child: AspectRatio(
                        aspectRatio: 1.42,
                        child: Container(
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                fit: BoxFit.fitWidth,
                                alignment: FractionalOffset.center,
                                image: FileImage(
                                  File(imagePath),
                                ),
                                // image: MemoryImage(
                                //     inputImage.bytes!
                                // )
                              )),
                        ),
                      )));
            },
          );
  }
}

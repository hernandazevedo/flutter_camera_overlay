import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<String> getAssetPath(String asset, {String package = "flutter_camera_overlay"}) async {
  final path = await getLocalPath("packages/$package/$asset");
  await Directory(dirname(path)).create(recursive: true);
  final file = File(path);
  if (!await file.exists()) {
    final byteData = await rootBundle.load("packages/$package/$asset");
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  }
  return file.path;
}

Future<String> getLocalPath(String path) async {
  return '${(await getApplicationSupportDirectory()).path}/$path';
}

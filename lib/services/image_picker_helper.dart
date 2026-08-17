import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'image_picker_helper_io.dart'
    if (dart.library.html) 'image_picker_helper_web.dart' as picker_impl;

class AppPickedFile {
  final Uint8List bytes;
  final String name;
  final String? path;

  AppPickedFile({
    required this.bytes,
    required this.name,
    this.path,
  });
}

class AppImagePicker {
  AppImagePicker._();

  static Future<AppPickedFile?> pickImage({
    bool fromCamera = false,
  }) async {
    return picker_impl.pickImagePlatform(fromCamera: fromCamera);
  }
}

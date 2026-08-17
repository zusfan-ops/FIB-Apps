// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'image_picker_helper.dart';

Future<AppPickedFile?> pickImagePlatform({bool fromCamera = false}) async {
  final completer = Completer<AppPickedFile?>();
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = 'image/*';

  if (fromCamera) {
    uploadInput.setAttribute('capture', 'environment');
  }

  uploadInput.onChange.listen((_) {
    final files = uploadInput.files;
    if (files != null && files.isNotEmpty) {
      final file = files[0];
      final reader = html.FileReader();

      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        Uint8List? bytes;

        if (result is Uint8List) {
          bytes = result;
        } else if (result is ByteBuffer) {
          bytes = result.asUint8List();
        } else if (result is List<int>) {
          bytes = Uint8List.fromList(result);
        }

        if (bytes != null) {
          if (!completer.isCompleted) {
            completer.complete(AppPickedFile(
              bytes: bytes,
              name: file.name.isNotEmpty
                  ? file.name
                  : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ));
          }
        } else {
          if (!completer.isCompleted) completer.complete(null);
        }
      });

      reader.onError.listen((_) {
        if (!completer.isCompleted) completer.complete(null);
      });

      reader.readAsArrayBuffer(file);
    } else {
      if (!completer.isCompleted) completer.complete(null);
    }
  });

  uploadInput.click();
  return completer.future;
}

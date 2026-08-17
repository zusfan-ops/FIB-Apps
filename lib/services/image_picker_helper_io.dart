import 'package:image_picker/image_picker.dart';

import 'image_picker_helper.dart';

Future<AppPickedFile?> pickImagePlatform({bool fromCamera = false}) async {
  final picker = ImagePicker();
  final source = fromCamera ? ImageSource.camera : ImageSource.gallery;

  final XFile? file = await picker.pickImage(
    source: source,
    maxWidth: 1600,
    maxHeight: 1600,
    imageQuality: 85,
  );

  if (file == null) return null;

  final bytes = await file.readAsBytes();
  return AppPickedFile(
    bytes: bytes,
    name: file.name.isNotEmpty ? file.name : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
    path: file.path,
  );
}

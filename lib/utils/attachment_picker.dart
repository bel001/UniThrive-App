import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AttachmentPicker {
  AttachmentPicker._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return null;
    final directory = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(directory.path, 'attachments'));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
    final savedPath = p.join(attachmentsDir.path, name);
    await File(file.path).copy(savedPath);
    return savedPath;
  }
}

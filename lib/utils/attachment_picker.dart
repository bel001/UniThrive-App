import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
    return _storeFile(file.path);
  }

  static Future<String?> pickAnyFile() async {
    final result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;
    if (path == null || path.isEmpty) return null;
    return _storeFile(path);
  }

  static Future<String> saveLink(String url) async {
    return url.trim();
  }

  static bool isLink(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static bool isImage(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final normalized = value.toLowerCase();
    return normalized.endsWith('.png') ||
        normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.webp') ||
        normalized.endsWith('.gif');
  }

  static bool isPdf(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return value.toLowerCase().endsWith('.pdf');
  }

  static String fileName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Adjunto';
    if (isLink(value)) return value;
    return p.basename(value);
  }

  static Future<String> _storeFile(String originalPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(directory.path, 'attachments'));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(originalPath)}';
    final savedPath = p.join(attachmentsDir.path, name);
    await File(originalPath).copy(savedPath);
    return savedPath;
  }

  /// Borra un adjunto local si es un archivo dentro del directorio de
  /// adjuntos de la app. Los enlaces (http/https) se ignoran.
  static Future<void> deleteStoredFile(String? value) async {
    if (value == null || isLink(value)) return;
    try {
      if (kIsWeb) return;
      final directory = await getApplicationDocumentsDirectory();
      final attachmentsDir = p.join(directory.path, 'attachments');
      if (!p.isWithin(attachmentsDir, value)) return;
      final file = File(value);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Nunca fallar por limpieza de archivos.
    }
  }
}

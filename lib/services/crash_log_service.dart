import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Registra errores no capturados en un archivo local para depuración.
/// Mantiene el archivo acotado (rotación simple por tamaño).
class CrashLogService {
  CrashLogService._();

  static const int _maxFileBytes = 64 * 1024;
  static File? _file;

  static Future<File> _resolveFile() async {
    final cached = _file;
    if (cached != null) return cached;
    final directory = await getApplicationDocumentsDirectory();
    final logsDir = Directory(p.join(directory.path, 'logs'));
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    final file = File(p.join(logsDir.path, 'crash_log.txt'));
    _file = file;
    return file;
  }

  static Future<void> log(
    Object error,
    StackTrace? stackTrace, {
    String source = 'async',
  }) async {
    if (kIsWeb) return;
    try {
      final file = await _resolveFile();
      final buffer = StringBuffer()
        ..writeln('--- ${DateTime.now().toIso8601String()} [$source] ---')
        ..writeln(error)
        ..writeln(stackTrace)
        ..writeln();
      var contents = await file.exists()
          ? await file.readAsString()
          : '';
      contents += buffer.toString();
      if (contents.length > _maxFileBytes) {
        contents = contents.substring(contents.length - _maxFileBytes);
      }
      await file.writeAsString(contents, flush: false);
    } catch (_) {
      // Nunca propagar un error del propio logger.
    }
  }

  /// Instala los handlers globales de error y delega el reporte a [onError].
  static void install() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      unawaited(log(details.exception, details.stack, source: 'flutter'));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(log(error, stack, source: 'uncaught'));
      return true;
    };
  }
}

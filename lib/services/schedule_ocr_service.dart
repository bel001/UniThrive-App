import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../utils/platform_capabilities.dart';

/// OCR en el dispositivo con ML Kit: lee el texto de una foto del horario
/// para que el asistente lo procese. Solo móvil (Android/iOS); el modelo se
/// descarga la primera vez (requiere internet una sola vez).
class ScheduleOcrService {
  ScheduleOcrService._();

  /// Extrae el texto visible en [imagePath]. Lanza [OcrException] con mensaje
  /// en español si no se puede procesar.
  static Future<String> recognizeText(String imagePath) async {
    if (!PlatformCapabilities.isMobile) {
      throw const OcrException(
        'La lectura de fotos está disponible en Android e iOS.',
      );
    }
    final recognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);
      final text = result.text.trim();
      if (text.isEmpty) {
        throw const OcrException(
          'No encontré texto en la foto. Prueba con más luz o más cerca.',
        );
      }
      return text;
    } on MissingPluginException {
      throw const OcrException(
        'El lector de fotos no está disponible en esta ejecución.',
      );
    } on PlatformException catch (error) {
      debugPrint('OCR falló: ${error.message}');
      throw const OcrException(
        'No pude leer la foto. Revisa tu conexión la primera vez (descarga el modelo) e inténtalo de nuevo.',
      );
    } catch (error) {
      if (error is OcrException) rethrow;
      throw const OcrException('No pude leer la foto. Inténtalo de nuevo.');
    } finally {
      try {
        await recognizer.close();
      } catch (_) {
        // Ignorar errores al liberar el reconocedor.
      }
    }
  }
}

class OcrException implements Exception {
  final String message;
  const OcrException(this.message);

  @override
  String toString() => message;
}

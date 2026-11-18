import 'dart:io';

import 'package:flutter/foundation.dart';

/// Capacidades por plataforma para degradar con gracia en web/linux,
/// donde voz, alarmas nativas y notificaciones locales no están soportadas.
class PlatformCapabilities {
  PlatformCapabilities._();

  static bool get isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Dictado por voz (speech_to_text) solo está disponible en móvil.
  static bool get supportsVoiceInput => isMobile;

  /// Alarmas exactas vía paquete `alarm` solo en móvil.
  static bool get supportsNativeAlarms => isMobile;

  /// Notificaciones locales solo en móvil.
  static bool get supportsLocalNotifications => isMobile;
}

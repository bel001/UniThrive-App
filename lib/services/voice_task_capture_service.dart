import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum VoiceCaptureAvailability { ready, denied, unsupported, unavailable, error }

class VoiceCaptureStartResult {
  final VoiceCaptureAvailability availability;
  final String? message;
  final String? localeId;

  const VoiceCaptureStartResult({
    required this.availability,
    this.message,
    this.localeId,
  });

  bool get canListen => availability == VoiceCaptureAvailability.ready;
}

class VoiceTaskCaptureService {
  VoiceTaskCaptureService._();

  static final VoiceTaskCaptureService instance = VoiceTaskCaptureService._();

  final SpeechToText _speech = SpeechToText();

  bool _initializeAttempted = false;
  bool _isInitialized = false;
  void Function(String status)? _statusSink;
  void Function(String message)? _errorSink;

  bool get isListening => _speech.isListening;

  Future<VoiceCaptureStartResult> startListening({
    required void Function(String transcript, bool isFinal) onTranscript,
    void Function(double level)? onSoundLevelChange,
    void Function(String status)? onStatusChanged,
    void Function(String message)? onError,
  }) async {
    _statusSink = onStatusChanged;
    _errorSink = onError;

    if (!_supportsRecognition) {
      return const VoiceCaptureStartResult(
        availability: VoiceCaptureAvailability.unsupported,
        message: 'La captura de voz aún no está disponible en esta plataforma.',
      );
    }

    try {
      final isReady = await _ensureInitialized();
      if (!isReady) {
        final hasPermission = await _hasPermission();
        return VoiceCaptureStartResult(
          availability: hasPermission
              ? VoiceCaptureAvailability.unavailable
              : VoiceCaptureAvailability.denied,
          message: hasPermission
              ? 'El reconocimiento de voz no está disponible en este dispositivo.'
              : 'Activa el permiso del micrófono para dictar tareas.',
        );
      }

      final localeId = await _resolvePreferredLocaleId();
      await _speech.listen(
        onResult: (result) =>
            onTranscript(result.recognizedWords, result.finalResult),
        localeId: localeId,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 5),
        onSoundLevelChange: onSoundLevelChange,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
        ),
      );

      return VoiceCaptureStartResult(
        availability: VoiceCaptureAvailability.ready,
        localeId: localeId,
      );
    } on MissingPluginException {
      return const VoiceCaptureStartResult(
        availability: VoiceCaptureAvailability.unsupported,
        message: 'La voz no está disponible en esta ejecución de la app.',
      );
    } on PlatformException catch (error) {
      return VoiceCaptureStartResult(
        availability: VoiceCaptureAvailability.error,
        message: error.message ?? 'No pude iniciar el reconocimiento de voz.',
      );
    } catch (_) {
      return const VoiceCaptureStartResult(
        availability: VoiceCaptureAvailability.error,
        message: 'No pude iniciar el micrófono. Inténtalo otra vez.',
      );
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {
      // Swallow platform-specific stop errors to avoid breaking the UI.
    }
  }

  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (_) {
      // Swallow platform-specific cancel errors to avoid breaking the UI.
    }
  }

  Future<bool> _ensureInitialized() async {
    if (_initializeAttempted && _isInitialized) {
      return _isInitialized;
    }

    _initializeAttempted = true;
    try {
      _isInitialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
        options: [SpeechToText.androidNoBluetooth],
      );
    } on MissingPluginException {
      _isInitialized = false;
    } on PlatformException {
      _isInitialized = false;
    } catch (_) {
      _isInitialized = false;
    }

    return _isInitialized;
  }

  Future<bool> _hasPermission() async {
    try {
      return await _speech.hasPermission;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _resolvePreferredLocaleId() async {
    try {
      final locales = await _speech.locales();
      const preferredLocales = ['es_PE', 'es_ES', 'es_MX', 'es_US', 'es'];
      for (final candidate in preferredLocales) {
        for (final locale in locales) {
          if (locale.localeId.toLowerCase() == candidate.toLowerCase()) {
            return locale.localeId;
          }
        }
      }

      for (final locale in locales) {
        if (locale.localeId.toLowerCase().startsWith('es')) {
          return locale.localeId;
        }
      }

      return (await _speech.systemLocale())?.localeId;
    } catch (_) {
      return null;
    }
  }

  void _handleStatus(String status) {
    _statusSink?.call(status);
  }

  void _handleError(SpeechRecognitionError error) {
    _errorSink?.call(_mapErrorMessage(error.errorMsg));
  }

  String _mapErrorMessage(String rawMessage) {
    switch (rawMessage) {
      case 'error_permission':
        return 'Activa el permiso del micrófono para usar el dictado.';
      case 'error_no_match':
        return 'No logré entender el dictado. Prueba una frase más corta.';
      case 'error_speech_timeout':
        return 'No escuché voz a tiempo. Puedes intentarlo de nuevo.';
      case 'error_network':
      case 'error_network_timeout':
        return 'La red interrumpió el reconocimiento de voz.';
      default:
        return 'El reconocimiento de voz se interrumpió. Inténtalo otra vez.';
    }
  }

  bool get _supportsRecognition {
    if (kIsWeb) {
      return true;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return true;
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }
}

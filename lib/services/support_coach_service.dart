import 'dart:math';

import '../models/support_message.dart';

class SupportCoachService {
  const SupportCoachService();

  static final Random _rand = Random();

  Future<SupportCoachReply> buildCoachMessage({
    required String mood,
    required String userText,
    required List<SupportMessage> history,
  }) async {
    return _fallbackReply(
      mood: mood,
      userText: userText,
      history: history,
    );
  }

  SupportCoachReply _fallbackReply({
    required String mood,
    required String userText,
    required List<SupportMessage> history,
  }) {
    final lower = userText.toLowerCase();
    String body;
    String? action;
    if (lower.contains('estres') || lower.contains('ansiedad')) {
      body =
          'Respiremos juntos. Acepta cómo te sientes y elige un micro paso amable para hoy.';
      action = 'Planear pausa consciente';
    } else if (lower.contains('cans') || lower.contains('agot')) {
      body =
          'Tu cuerpo pide calma. Permítete una pausa breve y luego retomamos.';
      action = 'Bloque corto de repaso';
    } else if (lower.contains('feliz') || lower.contains('logr')) {
      body =
          'Celebra ese impulso. Aprovecha la energía y concreta un paso sencillo ahora mismo.';
      action = 'Registrar logro y siguiente paso';
    } else if (lower.contains('no puedo') || lower.contains('bloque')) {
      body =
          'Dividamos la tarea: elige la parte más pequeña y hazla en 5 minutos.';
      action = 'Micro paso de 5 minutos';
    } else {
      final options = [
        'Estoy aquí para escucharte. Hagamos que tu siguiente acción sea ligera.',
        'No estás solo, avancemos con un paso amable.',
        'Toma aire y escribe el paso más pequeño que podrías dar.',
      ];
      body = options[_rand.nextInt(options.length)];
      action = 'Registrar micro paso';
    }
    final moodLine = _moodAffirmations[mood] ?? 'Confía en tu ritmo.';
    final response = '$body\n\n$moodLine';
    final message = SupportMessage(
      fromCoach: true,
      text: response,
      timestamp: DateTime.now(),
      actionLabel: action,
    );
    return SupportCoachReply(message: message, actionLabel: action);
  }

  static const Map<String, String> _moodAffirmations = {
    'Estresado/a': 'Un paso consciente basta para recuperar claridad.',
    'Motivado/a': 'Convierte esa motivación en avance concreto.',
    'Cansado/a': 'Celebra lo que ya hiciste; iremos despacio pero constante.',
    'Bloqueado/a': 'Los bloqueos hablan: escúchalos y responde con amabilidad.',
    'Ansioso/a': 'Nombrar lo que sientes ya es avanzar; no estás solo.',
  };
}

class SupportCoachReply {
  final SupportMessage message;
  final String? actionLabel;

  const SupportCoachReply({required this.message, this.actionLabel});
}

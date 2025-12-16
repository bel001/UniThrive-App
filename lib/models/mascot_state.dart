enum MascotMood {
  happy,
  excited,
  encouraging,
  celebrating,
  thinking,
  sleeping,
  sad,
  worried,
}

class MascotState {
  final MascotMood mood;
  final String message;
  final DateTime timestamp;

  const MascotState({
    required this.mood,
    required this.message,
    required this.timestamp,
  });

  MascotState copyWith({
    MascotMood? mood,
    String? message,
    DateTime? timestamp,
  }) {
    return MascotState(
      mood: mood ?? this.mood,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory MascotState.fromJson(Map<String, dynamic> json) {
    return MascotState(
      mood: MascotMood.values.firstWhere(
        (e) => e.name == json['mood'],
        orElse: () => MascotMood.happy,
      ),
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'mood': mood.name,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
  };
}

class MascotMessages {
  static const Map<MascotMood, List<String>> messagesByMood = {
    MascotMood.happy: [
      '¡Hola! ¿Listo para ser productivo hoy?',
      '¡Buenos días! Vamos a lograr cosas increíbles',
      '¡Qué bueno verte! ¿Qué haremos primero?',
    ],
    MascotMood.excited: [
      '¡Estás en racha! 🔥',
      '¡Wow! ¡Vas genial!',
      '¡Increíble progreso!',
    ],
    MascotMood.encouraging: [
      '¡Tú puedes! Un paso a la vez',
      'No te rindas, estás muy cerca',
      'Cada pequeño progreso cuenta',
      '¡Sigue así! Lo estás haciendo bien',
    ],
    MascotMood.celebrating: [
      '¡FELICIDADES! 🎉',
      '¡Lo lograste! ¡Eres increíble! 🌟',
      '¡Excelente trabajo! 🎊',
      '¡Nuevo logro desbloqueado! 🏆',
    ],
    MascotMood.thinking: [
      'Hmm... déjame ayudarte a planear esto',
      'Pensemos en la mejor estrategia',
      '¿Qué tal si dividimos esto en pasos más pequeños?',
    ],
    MascotMood.sleeping: [
      'Zzz... parece que no has estado activo',
      '¡Te extrañé! ¿Volvemos a la acción?',
      'Es hora de retomar el ritmo',
    ],
    MascotMood.sad: [
      'Está bien tener días difíciles',
      'No pasa nada, mañana será mejor',
      'Tómate un respiro si lo necesitas',
    ],
    MascotMood.worried: [
      '¡Cuidado! Tienes tareas pendientes',
      'Oye, no olvides tus metas de hoy',
      'Parece que la fecha límite se acerca',
    ],
  };

  static String getRandomMessage(MascotMood mood) {
    final messages = messagesByMood[mood] ?? messagesByMood[MascotMood.happy]!;
    final now = DateTime.now();
    final index = now.millisecond % messages.length;
    return messages[index];
  }

  static MascotState forTaskCompleted({required bool isFirstToday}) {
    return MascotState(
      mood: isFirstToday ? MascotMood.excited : MascotMood.happy,
      message: isFirstToday
          ? '¡Primera tarea del día completada! 🌟'
          : '¡Genial! Una tarea menos 💪',
      timestamp: DateTime.now(),
    );
  }

  static MascotState forStreakMilestone(int days) {
    return MascotState(
      mood: MascotMood.celebrating,
      message: '¡$days días de racha! ¡Eres imparable! 🔥',
      timestamp: DateTime.now(),
    );
  }

  static MascotState forLevelUp(int newLevel) {
    return MascotState(
      mood: MascotMood.celebrating,
      message: '¡Subiste al nivel $newLevel! 🎉',
      timestamp: DateTime.now(),
    );
  }

  static MascotState forAchievementUnlocked(String achievementTitle) {
    return MascotState(
      mood: MascotMood.celebrating,
      message: 'Nuevo logro: $achievementTitle 🏆',
      timestamp: DateTime.now(),
    );
  }

  static MascotState forInactivity(int days) {
    return MascotState(
      mood: days > 5 ? MascotMood.sad : MascotMood.sleeping,
      message: days > 5
          ? 'Te extraño mucho... ¿volvemos? 🥺'
          : '¡Bienvenido de vuelta! Te extrañé',
      timestamp: DateTime.now(),
    );
  }

  static MascotState forDailyGoal() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return MascotState(
        mood: MascotMood.happy,
        message: '¡Buenos días! Empecemos con energía ☀️',
        timestamp: DateTime.now(),
      );
    } else if (hour < 18) {
      return MascotState(
        mood: MascotMood.encouraging,
        message: '¡Ya es tarde! Sigamos avanzando 💪',
        timestamp: DateTime.now(),
      );
    } else {
      return MascotState(
        mood: MascotMood.thinking,
        message: '¿Terminamos algo antes de descansar? 🌙',
        timestamp: DateTime.now(),
      );
    }
  }
}

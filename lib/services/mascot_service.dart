import '../models/mascot_state.dart';

class MascotService {
  MascotState _currentState = MascotState(
    mood: MascotMood.happy,
    message: MascotMessages.getRandomMessage(MascotMood.happy),
    timestamp: DateTime.now(),
  );

  MascotState get currentState => _currentState;

  void updateState(MascotState newState) {
    _currentState = newState;
  }

  MascotState getGreeting() {
    return MascotMessages.forDailyGoal();
  }

  MascotState onTaskCompleted({
    required bool isFirstToday,
    required int streak,
  }) {
    if (streak > 0 && streak % 5 == 0) {
      return MascotMessages.forStreakMilestone(streak);
    }
    return MascotMessages.forTaskCompleted(isFirstToday: isFirstToday);
  }

  MascotState onFocusSessionCompleted(int minutesCompleted) {
    if (minutesCompleted >= 60) {
      return MascotState(
        mood: MascotMood.celebrating,
        message: '¡Una hora completa de enfoque! ¡Eres una máquina! 🧠',
        timestamp: DateTime.now(),
      );
    } else if (minutesCompleted >= 25) {
      return MascotState(
        mood: MascotMood.excited,
        message: '¡Excelente sesión de enfoque! 💪',
        timestamp: DateTime.now(),
      );
    } else {
      return MascotState(
        mood: MascotMood.happy,
        message: '¡Buen trabajo! Cada minuto cuenta ✨',
        timestamp: DateTime.now(),
      );
    }
  }

  MascotState onLevelUp(int newLevel) {
    return MascotMessages.forLevelUp(newLevel);
  }

  MascotState onAchievementUnlocked(String achievementTitle) {
    return MascotMessages.forAchievementUnlocked(achievementTitle);
  }

  MascotState onInactivity(int days) {
    return MascotMessages.forInactivity(days);
  }

  MascotState onProjectCompleted(String projectName) {
    return MascotState(
      mood: MascotMood.celebrating,
      message: '¡Proyecto "$projectName" completado! 🎉',
      timestamp: DateTime.now(),
    );
  }

  MascotState onDeadlineApproaching() {
    return MascotState(
      mood: MascotMood.worried,
      message: '¡Oye! Tienes tareas con fechas límite cercanas ⏰',
      timestamp: DateTime.now(),
    );
  }

  MascotState onDailyGoalAchieved() {
    return MascotState(
      mood: MascotMood.celebrating,
      message: '¡Meta diaria cumplida! ¡Eres increíble! 🌟',
      timestamp: DateTime.now(),
    );
  }

  MascotState onDailyProgress({
    required int completed,
    required int total,
    required bool isFirstToday,
  }) {
    if (total == 0) {
      return MascotState(
        mood: MascotMood.encouraging,
        message: 'Sin tareas hoy, crea una y avanza un paso.',
        timestamp: DateTime.now(),
      );
    }
    final percent = total == 0 ? 0 : (completed / total * 100).round();
    if (percent >= 100) {
      return MascotMessages.forAchievementUnlocked('Plan diario completado');
    }
    if (isFirstToday) {
      return MascotMessages.forTaskCompleted(isFirstToday: true);
    }
    if (percent >= 60) {
      return MascotState(
        mood: MascotMood.excited,
        message: 'Llevas $percent% del día, ¡remata el cierre! 💫',
        timestamp: DateTime.now(),
      );
    }
    return MascotState(
      mood: MascotMood.encouraging,
      message: 'Progreso $percent%. Un paso más y lo logramos.',
      timestamp: DateTime.now(),
    );
  }

  MascotState getEncouragingMessage() {
    return MascotState(
      mood: MascotMood.encouraging,
      message: MascotMessages.getRandomMessage(MascotMood.encouraging),
      timestamp: DateTime.now(),
    );
  }

  MascotState getRandomHappyMessage() {
    return MascotState(
      mood: MascotMood.happy,
      message: MascotMessages.getRandomMessage(MascotMood.happy),
      timestamp: DateTime.now(),
    );
  }
}

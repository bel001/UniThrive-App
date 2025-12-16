import '../models/task.dart';
import '../models/pomodoro_session.dart';

class SmartReminders {
  /// Sugiere la mejor hora para trabajar basado en historial
  static DateTime? suggestBestTime(List<PomodoroSession> allSessions) {
    if (allSessions.isEmpty) return null;

    // Encontrar la hora más común
    final hourCount = <int, int>{};

    for (final session in allSessions) {
      if (!session.isBreak && session.wasCompleted) {
        final hour = session.startTime.hour;
        hourCount[hour] = (hourCount[hour] ?? 0) + 1;
      }
    }

    if (hourCount.isEmpty) return null;

    final bestHour = hourCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Crear fecha con la mejor hora, mañana
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, bestHour, 0);
  }

  /// Estima tiempo restante basado en tareas similares
  static int estimateRemainingMinutes(Task currentTask, List<Task> allTasks) {
    // Filtrar tareas completadas del mismo proyecto
    final similarTasks = allTasks
        .where(
          (t) =>
              t.completed &&
              t.projectId == currentTask.projectId &&
              t.timeSpentMinutes > 0 &&
              t.id != currentTask.id,
        )
        .toList();

    if (similarTasks.isEmpty) {
      // Si no hay tareas similares, estimar 60 minutos por defecto
      return 60;
    }

    // Promedio de tiempo de tareas similares
    final avgTime =
        similarTasks.fold<int>(0, (sum, task) => sum + task.timeSpentMinutes) ~/
        similarTasks.length;

    // Restar tiempo ya dedicado
    final remaining = avgTime - currentTask.timeSpentMinutes;
    return remaining > 0 ? remaining : 0;
  }

  /// Calcula progreso vs estimado
  static double calculateProgress(Task task, List<Task> allTasks) {
    final estimated =
        estimateRemainingMinutes(task, allTasks) + task.timeSpentMinutes;
    if (estimated == 0) return 0.0;
    return task.timeSpentMinutes / estimated;
  }

  /// Genera mensaje de sugerencia
  static String generateSuggestion(List<PomodoroSession> sessions) {
    final suggestion = suggestBestTime(sessions);
    if (suggestion == null) {
      return 'Empieza cuando quieras 💪';
    }

    final hour = suggestion.hour;
    final hourStr = '${hour.toString().padLeft(2, '0')}:00';

    return 'Usualmente trabajas mejor a las $hourStr';
  }

  /// Formatea tiempo estimado
  static String formatEstimate(int minutes) {
    if (minutes == 0) return 'Sin estimación';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) return '~${mins}min';
    if (mins == 0) return '~${hours}h';
    return '~${hours}h ${mins}min';
  }
}

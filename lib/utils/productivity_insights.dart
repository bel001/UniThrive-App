import '../models/pomodoro_session.dart';

class ProductivityInsights {
  static Map<String, dynamic> analyze(List<PomodoroSession> allSessions) {
    if (allSessions.isEmpty) {
      return {
        'bestDayOfWeek': 'Sin datos',
        'bestHourOfDay': 'Sin datos',
        'averageSessionsPerDay': 0.0,
        'totalProductiveHours': 0.0,
        'currentStreak': 0,
      };
    }

    // Filtrar solo sesiones de trabajo completadas
    final workSessions = allSessions
        .where((s) => !s.isBreak && s.wasCompleted)
        .toList();

    if (workSessions.isEmpty) {
      return {
        'bestDayOfWeek': 'Sin datos',
        'bestHourOfDay': 'Sin datos',
        'averageSessionsPerDay': 0.0,
        'totalProductiveHours': 0.0,
        'currentStreak': 0,
      };
    }

    return {
      'bestDayOfWeek': _calculateBestDay(workSessions),
      'bestHourOfDay': _calculateBestHour(workSessions),
      'averageSessionsPerDay': _calculateAverage(workSessions),
      'totalProductiveHours': _calculateTotalHours(workSessions),
      'currentStreak': _calculateStreak(workSessions),
    };
  }

  static String _calculateBestDay(List<PomodoroSession> sessions) {
    final dayCount = <int, int>{};

    for (final session in sessions) {
      final day = session.startTime.weekday;
      dayCount[day] = (dayCount[day] ?? 0) + 1;
    }

    if (dayCount.isEmpty) return 'Sin datos';

    final bestDay = dayCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return days[bestDay - 1];
  }

  static String _calculateBestHour(List<PomodoroSession> sessions) {
    final hourCount = <int, int>{};

    for (final session in sessions) {
      final hour = session.startTime.hour;
      hourCount[hour] = (hourCount[hour] ?? 0) + 1;
    }

    if (hourCount.isEmpty) return 'Sin datos';

    final bestHour = hourCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    return '${bestHour.toString().padLeft(2, '0')}:00 - ${(bestHour + 1).toString().padLeft(2, '0')}:00';
  }

  static double _calculateAverage(List<PomodoroSession> sessions) {
    if (sessions.isEmpty) return 0.0;

    final uniqueDays = <DateTime>{};
    for (final session in sessions) {
      final day = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      uniqueDays.add(day);
    }

    return sessions.length / uniqueDays.length;
  }

  static double _calculateTotalHours(List<PomodoroSession> sessions) {
    final totalMinutes = sessions.fold<int>(
      0,
      (sum, session) => sum + session.actualDurationMinutes,
    );
    return totalMinutes / 60.0;
  }

  static int _calculateStreak(List<PomodoroSession> sessions) {
    if (sessions.isEmpty) return 0;

    // Crear un Set de fechas únicas (normalizadas a medianoche)
    final uniqueDates = sessions.map((s) {
      return DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
    }).toSet();

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Verificar si hoy tiene sesión
    if (!uniqueDates.any((d) => d.isAtSameMomentAs(todayDate))) {
      return 0;
    }

    int streak = 1;
    DateTime checkDate = todayDate.subtract(const Duration(days: 1));

    // Verificar días anteriores
    for (int i = 0; i < 365; i++) {
      final hasSession = uniqueDates.any((d) => d.isAtSameMomentAs(checkDate));

      if (hasSession) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }
}

enum AchievementCategory {
  streak,
  completion,
  focusTime,
  projects,
  social,
  pomodoroConsistency,
}

enum AchievementRarity { common, rare, epic, legendary }

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int requiredValue;
  final int xpReward;
  final bool unlocked;
  final DateTime? unlockedAt;
  final int currentProgress;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.category,
    this.rarity = AchievementRarity.common,
    required this.requiredValue,
    this.xpReward = 100,
    this.unlocked = false,
    this.unlockedAt,
    this.currentProgress = 0,
  });

  Achievement copyWith({
    bool? unlocked,
    DateTime? unlockedAt,
    int? currentProgress,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      iconEmoji: iconEmoji,
      category: category,
      rarity: rarity,
      requiredValue: requiredValue,
      xpReward: xpReward,
      unlocked: unlocked ?? this.unlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      currentProgress: currentProgress ?? this.currentProgress,
    );
  }

  double get progressPercent =>
      (currentProgress / requiredValue * 100).clamp(0, 100);

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconEmoji: json['iconEmoji'] as String,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AchievementCategory.completion,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      requiredValue: json['requiredValue'] as int,
      xpReward: json['xpReward'] as int? ?? 100,
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      currentProgress: json['currentProgress'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'iconEmoji': iconEmoji,
    'category': category.name,
    'rarity': rarity.name,
    'requiredValue': requiredValue,
    'xpReward': xpReward,
    'unlocked': unlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'currentProgress': currentProgress,
  };
}

// Predefined achievements
class PredefinedAchievements {
  static List<Achievement> get all => [
    // Streak achievements
    Achievement(
      id: 'streak_5',
      title: 'Ritmo Inicial',
      description: 'Mantén una racha de 5 días',
      iconEmoji: '🔥',
      category: AchievementCategory.streak,
      rarity: AchievementRarity.common,
      requiredValue: 5,
      xpReward: 50,
    ),
    Achievement(
      id: 'streak_10',
      title: 'Anti-Procrastinador',
      description: 'Mantén una racha de 10 días',
      iconEmoji: '⚡',
      category: AchievementCategory.streak,
      rarity: AchievementRarity.rare,
      requiredValue: 10,
      xpReward: 150,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Modo Leyenda',
      description: 'Mantén una racha de 30 días',
      iconEmoji: '👑',
      category: AchievementCategory.streak,
      rarity: AchievementRarity.epic,
      requiredValue: 30,
      xpReward: 500,
    ),

    // Completion achievements
    Achievement(
      id: 'tasks_10',
      title: 'Primeros Pasos',
      description: 'Completa 10 tareas',
      iconEmoji: '✅',
      category: AchievementCategory.completion,
      rarity: AchievementRarity.common,
      requiredValue: 10,
      xpReward: 50,
    ),
    Achievement(
      id: 'tasks_50',
      title: 'Productivo',
      description: 'Completa 50 tareas',
      iconEmoji: '🎯',
      category: AchievementCategory.completion,
      rarity: AchievementRarity.rare,
      requiredValue: 50,
      xpReward: 200,
    ),
    Achievement(
      id: 'tasks_100',
      title: 'Imparable',
      description: 'Completa 100 tareas',
      iconEmoji: '🚀',
      category: AchievementCategory.completion,
      rarity: AchievementRarity.epic,
      requiredValue: 100,
      xpReward: 500,
    ),

    // Focus time achievements
    Achievement(
      id: 'focus_5h',
      title: 'Enfocado',
      description: 'Acumula 5 horas de enfoque',
      iconEmoji: '🎧',
      category: AchievementCategory.focusTime,
      rarity: AchievementRarity.common,
      requiredValue: 300, // minutes
      xpReward: 75,
    ),
    Achievement(
      id: 'focus_25h',
      title: 'Maestro del Enfoque',
      description: 'Acumula 25 horas de enfoque',
      iconEmoji: '🧠',
      category: AchievementCategory.focusTime,
      rarity: AchievementRarity.rare,
      requiredValue: 1500,
      xpReward: 300,
    ),
    Achievement(
      id: 'focus_100h',
      title: 'Concentración Zen',
      description: 'Acumula 100 horas de enfoque',
      iconEmoji: '🧘',
      category: AchievementCategory.focusTime,
      rarity: AchievementRarity.legendary,
      requiredValue: 6000,
      xpReward: 1000,
    ),

    // Project achievements
    Achievement(
      id: 'projects_3',
      title: 'Multitarea',
      description: 'Completa 3 proyectos',
      iconEmoji: '📚',
      category: AchievementCategory.projects,
      rarity: AchievementRarity.common,
      requiredValue: 3,
      xpReward: 100,
    ),
    Achievement(
      id: 'projects_10',
      title: 'Gestor Estrella',
      description: 'Completa 10 proyectos',
      iconEmoji: '⭐',
      category: AchievementCategory.projects,
      rarity: AchievementRarity.epic,
      requiredValue: 10,
      xpReward: 400,
    ),

    // Pomodoro consistency achievements
    Achievement(
      id: 'pomo_streak_3',
      title: 'Calentando Motores',
      description: 'Haz sesiones Pomodoro 3 días seguidos',
      iconEmoji: '⏱️',
      category: AchievementCategory.pomodoroConsistency,
      rarity: AchievementRarity.common,
      requiredValue: 3,
      xpReward: 75,
    ),
    Achievement(
      id: 'pomo_streak_7',
      title: 'Constancia Pro',
      description: 'Haz sesiones Pomodoro 7 días seguidos',
      iconEmoji: '🧩',
      category: AchievementCategory.pomodoroConsistency,
      rarity: AchievementRarity.rare,
      requiredValue: 7,
      xpReward: 200,
    ),
    Achievement(
      id: 'pomo_streak_14',
      title: 'Zen del Enfoque',
      description: 'Haz sesiones Pomodoro 14 días seguidos',
      iconEmoji: '🧘',
      category: AchievementCategory.pomodoroConsistency,
      rarity: AchievementRarity.epic,
      requiredValue: 14,
      xpReward: 450,
    ),
  ];
}

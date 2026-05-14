import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../state/app_state.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Logros'), centerTitle: true),
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          final unlocked = appState.unlockedAchievements;
          final locked = appState.lockedAchievements;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildStatsCard(context, appState),
              const SizedBox(height: 24),
              Text('Logros desbloqueados', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              if (unlocked.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Aún no has desbloqueado logros. ¡Sigue trabajando!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...unlocked.map(
                  (achievement) => _buildAchievementCard(
                    context,
                    achievement,
                    unlocked: true,
                  ),
                ),
              const SizedBox(height: 24),
              Text('Logros por desbloquear', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...locked.map(
                (achievement) => _buildAchievementCard(
                  context,
                  achievement,
                  unlocked: false,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, AppState appState) {
    final total = appState.achievements.length;
    final unlocked = appState.unlockedAchievements.length;
    final percentage = total > 0 ? (unlocked / total * 100).toInt() : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9FCFBB), Color(0xFFB39DFF)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Text(
              'Progreso de logros',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 320;
                final itemWidth = compact
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 2;
                return Wrap(
                  alignment: WrapAlignment.spaceAround,
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _buildStatItem('Desbloqueados', '$unlocked'),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildStatItem('Total', '$total'),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildStatItem('Completado', '$percentage%'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    Achievement achievement, {
    required bool unlocked,
  }) {
    final theme = Theme.of(context);
    final rarityColor = _getRarityColor(achievement.rarity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: unlocked ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: unlocked
            ? BorderSide(color: rarityColor, width: 2)
            : BorderSide.none,
      ),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.5,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: rarityColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    achievement.iconEmoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final badge = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: rarityColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getRarityLabel(achievement.rarity),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: rarityColor,
                            ),
                          ),
                        );
                        final title = Text(
                          achievement.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: unlocked
                                ? theme.textTheme.bodyLarge?.color
                                : theme.textTheme.bodyMedium?.color,
                          ),
                        );

                        if (constraints.maxWidth < 220) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [title, const SizedBox(height: 8), badge],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: title),
                            const SizedBox(width: 8),
                            badge,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (!unlocked) ...[
                      LinearProgressIndicator(
                        value: achievement.progressPercent / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: rarityColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${achievement.currentProgress} / ${achievement.requiredValue}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${achievement.xpReward} XP',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return const Color(0xFF9E9E9E);
      case AchievementRarity.rare:
        return const Color(0xFF2196F3);
      case AchievementRarity.epic:
        return const Color(0xFF9C27B0);
      case AchievementRarity.legendary:
        return const Color(0xFFFFB300);
    }
  }

  String _getRarityLabel(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'COMÚN';
      case AchievementRarity.rare:
        return 'RARO';
      case AchievementRarity.epic:
        return 'ÉPICO';
      case AchievementRarity.legendary:
        return 'LEGENDARIO';
    }
  }
}

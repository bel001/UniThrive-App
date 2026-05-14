import 'package:flutter/material.dart';

import '../../core/design_tokens.dart';
import '../../models/task.dart';
import '../../services/notification_service.dart';
import '../../state/app_state.dart';
import '../../widgets/uni_card.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final tasks =
        appState.allTasks
            .where((task) => !task.completed && task.dueDate != null)
            .toList()
          ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final upcomingTasks = tasks.take(5).toList();

    final schedule =
        appState.scheduleBlocks
            .where((block) => block.start.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final upcomingBlocks = schedule.take(5).toList();

    final nextReminder =
        <_UpcomingItem>[
          ...upcomingTasks.map(
            (task) => _UpcomingItem(
              icon: Icons.checklist_rounded,
              title: task.title,
              subtitle: task.friendlyLabel ?? 'Sin fecha definida',
              moment: task.dueDate,
            ),
          ),
          ...upcomingBlocks.map(
            (block) => _UpcomingItem(
              icon: Icons.event_rounded,
              title: block.title,
              subtitle: '${block.location} · ${block.start.friendlySlot}',
              moment: block.start,
            ),
          ),
        ]..sort((a, b) {
          final aMoment = a.moment ?? DateTime(2100);
          final bMoment = b.moment ?? DateTime(2100);
          return aMoment.compareTo(bMoment);
        });

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.screenHorizontal,
                12,
                DesignTokens.screenHorizontal,
                132,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Recordatorios', style: theme.textTheme.displayLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Controla permisos, próximos avisos y lo que viene en tu jornada.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  UniCard(
                    radius: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.notifications_active_outlined,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          appState.taskRemindersEnabled ||
                                  appState.classRemindersEnabled
                              ? 'Tu sistema de avisos está activo'
                              : 'Los recordatorios están en pausa',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          nextReminder.isEmpty
                              ? 'Todavía no hay eventos próximos en la cola.'
                              : 'Siguiente aviso: ${nextReminder.first.title}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _InfoPill(
                              icon: Icons.schedule_rounded,
                              label:
                                  '${appState.reminderLeadMinutes} min antes',
                            ),
                            _InfoPill(
                              icon: Icons.check_circle_outline,
                              label:
                                  '${upcomingTasks.length + upcomingBlocks.length} próximos avisos',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Acciones rápidas',
                    subtitle: 'Resuelve permisos y acceso al sistema.',
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 360;
                      if (stacked) {
                        return Column(
                          children: [
                            _ActionCard(
                              icon: Icons.verified_user_outlined,
                              title: 'Verificar permisos',
                              subtitle:
                                  'Confirma que la app puede avisarte a tiempo.',
                              primary: true,
                              onTap: () => _handlePermissionRequest(context),
                            ),
                            const SizedBox(height: 12),
                            _ActionCard(
                              icon: Icons.settings_outlined,
                              title: 'Abrir ajustes del sistema',
                              subtitle:
                                  'Cambia permisos o notificaciones del dispositivo.',
                              onTap: NotificationService
                                  .openSystemNotificationSettings,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.verified_user_outlined,
                              title: 'Verificar permisos',
                              subtitle:
                                  'Confirma que la app puede avisarte a tiempo.',
                              primary: true,
                              onTap: () => _handlePermissionRequest(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.settings_outlined,
                              title: 'Abrir ajustes',
                              subtitle:
                                  'Gestiona alertas y permisos del sistema.',
                              onTap: NotificationService
                                  .openSystemNotificationSettings,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'Tareas próximas',
                    subtitle: 'Lo que necesita atención pronto.',
                  ),
                  const SizedBox(height: 12),
                  if (upcomingTasks.isEmpty)
                    const _TimelineEmptyCard(
                      icon: Icons.task_alt_rounded,
                      title: 'No hay tareas con recordatorios activos.',
                      subtitle:
                          'Cuando agregues fechas y avisos, aparecerán aquí.',
                    )
                  else
                    ...upcomingTasks.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TimelineCard(
                          icon: Icons.checklist_rounded,
                          title: task.title,
                          subtitle:
                              'Entrega ${task.friendlyLabel ?? 'sin fecha'}',
                          badge: task.customReminderMinutes == null
                              ? 'Predeterminado'
                              : '${task.customReminderMinutes} min',
                          highlightColor: scheme.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _SectionHeader(
                    title: 'Clases y eventos',
                    subtitle: 'Tu calendario próximo en una sola vista.',
                  ),
                  const SizedBox(height: 12),
                  if (upcomingBlocks.isEmpty)
                    const _TimelineEmptyCard(
                      icon: Icons.event_available_rounded,
                      title: 'No hay bloques próximos en el calendario.',
                      subtitle:
                          'Cuando añadas clases o sesiones, las verás aquí.',
                    )
                  else
                    ...upcomingBlocks.map(
                      (block) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TimelineCard(
                          icon: Icons.event_rounded,
                          title: block.title,
                          subtitle:
                              '${block.location} · ${block.start.friendlySlot} - ${block.end.friendlySlot}',
                          badge: _friendlyDay(block.start),
                          highlightColor: const Color(0xFF5C8DF6),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePermissionRequest(BuildContext context) async {
    final granted = await NotificationService.ensurePermissions();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Permisos concedidos correctamente.'
              : 'No se pudieron conceder los permisos. Revisa los ajustes del sistema.',
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = primary
        ? scheme.primaryContainer
        : scheme.surfaceContainerLow;
    final iconBackground = primary
        ? scheme.primary.withValues(alpha: 0.12)
        : scheme.surfaceContainerHighest;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: UniCard(
        color: background,
        radius: 28,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(subtitle, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.highlightColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return UniCard(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 290;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: highlightColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: highlightColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: stacked ? 3 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (!stacked) ...[
                    const SizedBox(width: 12),
                    _InfoPill(
                      icon: Icons.bolt_outlined,
                      label: badge,
                      dense: true,
                    ),
                  ],
                ],
              ),
              if (stacked) ...[
                const SizedBox(height: 12),
                _InfoPill(icon: Icons.bolt_outlined, label: badge, dense: true),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TimelineEmptyCard extends StatelessWidget {
  const _TimelineEmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return UniCard(
      radius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(height: 14),
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(subtitle, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dense ? 140 : 220),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: dense ? 14 : 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingItem {
  const _UpcomingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.moment,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime? moment;
}

String _friendlyDay(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(value.year, value.month, value.day);
  final difference = target.difference(today).inDays;

  if (difference == 0) {
    return 'Hoy';
  }
  if (difference == 1) {
    return 'Mañana';
  }
  return '${value.day}/${value.month}';
}

extension on DateTime {
  String get friendlySlot =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

extension on Task {
  String? get friendlyLabel {
    if (dueDate == null) return null;
    return '${dueDate!.day}/${dueDate!.month} · ${dueDate!.hour.toString().padLeft(2, '0')}:${dueDate!.minute.toString().padLeft(2, '0')}';
  }
}

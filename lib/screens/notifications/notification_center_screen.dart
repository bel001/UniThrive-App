import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../state/app_state.dart';
import '../../models/task.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final tasks = appState.allTasks
        .where((task) => !task.completed && task.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    final upcomingTasks = tasks.take(5).toList();
    final schedule = appState.scheduleBlocks.where((block) => block.start.isAfter(DateTime.now())).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final upcomingBlocks = schedule.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de recordatorios'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          ElevatedButton.icon(
            onPressed: () => _handlePermissionRequest(context),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Verificar permisos de notificación'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => NotificationService.openSystemNotificationSettings(),
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Abrir ajustes del sistema'),
          ),
          const SizedBox(height: 24),
          Text('Tareas próximas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (upcomingTasks.isEmpty)
            const Text('No hay tareas con recordatorios activos.')
          else
            ...upcomingTasks.map((task) => _ReminderTile(
                  icon: Icons.checklist_outlined,
                  title: task.title,
                  subtitle: 'Para ${task.friendlyLabel ?? 'Sin fecha'}',
                )),
          const SizedBox(height: 24),
          Text('Clases y eventos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (upcomingBlocks.isEmpty)
            const Text('No tienes clases en el calendario.')
          else
            ...upcomingBlocks.map(
              (block) => _ReminderTile(
                icon: Icons.event,
                title: block.title,
                subtitle: '${block.location} · ${block.start.friendlySlot} - ${block.end.friendlySlot}',
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handlePermissionRequest(BuildContext context) async {
    final granted = await NotificationService.ensurePermissions();
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          granted ? 'Permisos concedidos correctamente.' : 'No se pudieron conceder los permisos. Revisa los ajustes del sistema.',
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ReminderTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

extension on DateTime {
  String get friendlySlot => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

extension on Task {
  String? get friendlyLabel {
    if (dueDate == null) return null;
    return '${dueDate!.day}/${dueDate!.month} ${dueDate!.hour.toString().padLeft(2, '0')}:${dueDate!.minute.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../state/app_state.dart';
import '../../widgets/soft_page_route.dart';
import '../../widgets/uni_card.dart';
import '../notifications/notification_center_screen.dart';
import '../tasks/task_history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final isDarkMode = appState.themeMode == ThemeMode.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text('Ajustes', style: theme.textTheme.displayLarge),
            const SizedBox(height: 20),
            UniCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFDAD7FE),
                    child: Text(
                      _initials(appState.userName),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9FCFBB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appState.userEmail,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openAccountManager(context, appState),
                    child: const Text('Gestionar cuenta'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Ajustes de la aplicación',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            UniCard(
              child: Column(
                children: [
                  _SettingSwitchTile(
                    icon: Icons.nightlight_round,
                    title: 'Apariencia',
                    subtitle: isDarkMode ? 'Modo oscuro' : 'Modo claro',
                    value: isDarkMode,
                    onChanged: (value) => appState.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    ),
                  ),
                  const Divider(height: 8),
                  _SettingTile(
                    icon: Icons.notifications_none,
                    title: 'Notificaciones y alertas',
                    subtitle: 'Recordatorios y mensajes',
                    onTap: () => _openNotificationSettings(context, appState),
                  ),
                  const Divider(height: 8),
                  _SettingTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Centro de recordatorios',
                    subtitle: 'Consulta avisos y permisos',
                    onTap: () => Navigator.of(context).push(
                      SoftPageRoute(
                        builder: (_) => const NotificationCenterScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 8),
                  _SettingTile(
                    icon: Icons.history,
                    title: 'Historial de tiempo',
                    subtitle: 'Ver tiempo dedicado a tareas',
                    onTap: () => Navigator.of(context).push(
                      SoftPageRoute(builder: (_) => const TaskHistoryScreen()),
                    ),
                  ),
                  const Divider(height: 8),
                  _SettingTile(
                    icon: Icons.music_note_outlined,
                    title: 'Sonidos de alarma',
                    subtitle: 'Actual: ${appState.alarmSound}',
                    onTap: () => _openSoundPicker(context, appState),
                  ),
                  const Divider(height: 8),
                  _SettingSwitchTile(
                    icon: Icons.emoji_emotions_outlined,
                    title: 'Mensajes de ánimo',
                    subtitle: 'Recibe recordatorios motivacionales',
                    value: appState.motivationalMessages,
                    onChanged: (_) => appState.toggleMotivationMessages(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Soporte', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            UniCard(
              child: Column(
                children: [
                  _SettingTile(
                    icon: Icons.info_outline,
                    title: 'Acerca de UniThrive',
                    onTap: () => _showAbout(context),
                  ),
                  const Divider(height: 8),
                  _SettingTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Política de privacidad',
                    onTap: () => _showPrivacy(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF476F),
                side: const BorderSide(color: Color(0xFFEF476F)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              onPressed: () => _confirmSignOut(context, appState),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'U';
  return trimmed.substring(0, 1).toUpperCase();
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

void _openNotificationSettings(BuildContext context, AppState appState) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Text(
                  'Notificaciones y alertas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Activa o desactiva los recordatorios inteligentes. Puedes volver a solicitar permisos desde los ajustes del sistema.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recordatorios de clases'),
                  subtitle: const Text(
                    'Avisos antes de tus clases y reuniones',
                  ),
                  value: appState.classRemindersEnabled,
                  onChanged: (value) async {
                    if (value) {
                      final granted =
                          await NotificationService.ensurePermissions();
                      if (!granted) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Activa los permisos de notificaciones en el sistema.',
                              ),
                            ),
                          );
                        }
                        return;
                      }
                    }
                    appState.setClassReminders(value);
                    setSheetState(() {});
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Recordatorios de tareas'),
                  subtitle: const Text(
                    'Alertas antes de cada tarea programada',
                  ),
                  value: appState.taskRemindersEnabled,
                  onChanged: (value) async {
                    if (value) {
                      final granted =
                          await NotificationService.ensurePermissions();
                      if (!granted) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Activa los permisos de notificaciones en el sistema.',
                              ),
                            ),
                          );
                        }
                        return;
                      }
                    }
                    appState.setTaskReminders(value);
                    setSheetState(() {});
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Anticipación de recordatorios'),
                  subtitle: Text(
                    'Te avisamos ${appState.reminderLeadMinutes} min antes',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showReminderLeadPicker(context, appState),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mensajes de ánimo'),
                  subtitle: const Text(
                    'Pequeños empujones para mantener la motivación',
                  ),
                  value: appState.motivationalMessages,
                  onChanged: (_) {
                    appState.toggleMotivationMessages();
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

void _openAccountManager(BuildContext context, AppState appState) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final profiles = appState.profiles;
            final activeId = appState.activeProfileSummary?.id;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Text(
                  'Perfiles de estudio',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...profiles.map(
                  (profile) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      profile.id == activeId
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      profile.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(profile.email),
                    trailing: profile.id == activeId || profiles.length == 1
                        ? null
                        : IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              appState.deleteUserProfile(profile.id);
                              setSheetState(() {});
                            },
                          ),
                    onTap: () {
                      appState.switchUserProfile(profile.id);
                      setSheetState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final name = await _promptProfileName(context);
                    if (name != null && name.trim().isNotEmpty) {
                      appState.addUserProfile(name.trim());
                      setSheetState(() {});
                    }
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Agregar perfil'),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

Future<String?> _promptProfileName(BuildContext context) async {
  final controller = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Nombre del nuevo perfil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ej. María - Ingeniería'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Crear'),
          ),
        ],
      );
    },
  );
  if (confirmed == true) {
    return controller.text;
  }
  return null;
}

void _openSoundPicker(BuildContext context, AppState appState) {
  final options = ['Clásico', 'Olas', 'Campana', 'Minimal'];
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (sound) => ListTile(
                  title: Text(sound),
                  trailing: sound == appState.alarmSound
                      ? const Icon(Icons.check, color: Color(0xFF7C4DFF))
                      : null,
                  onTap: () {
                    appState.setAlarmSound(sound);
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sonido seleccionado: $sound')),
                    );
                  },
                ),
              )
              .toList(),
        ),
      );
    },
  );
}

void _showReminderLeadPicker(BuildContext context, AppState appState) {
  final options = [5, 10, 15, 30, 60, 120];
  showModalBottomSheet<int>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (minutes) => ListTile(
                  title: Text('Recordar $minutes min antes'),
                  trailing: minutes == appState.reminderLeadMinutes
                      ? const Icon(Icons.check, color: Color(0xFF7C4DFF))
                      : null,
                  onTap: () {
                    appState.setReminderLeadMinutes(minutes);
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Usaremos recordatorios $minutes min antes.',
                        ),
                      ),
                    );
                  },
                ),
              )
              .toList(),
        ),
      );
    },
  );
}

void _showAbout(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'UniThrive',
    applicationVersion: '1.0.0',
    applicationIcon: const Icon(Icons.auto_stories_outlined),
    children: const [
      Text(
        'UniThrive te acompaña a planificar tus metas, cuidar tu energía y estudiar con intención.',
      ),
    ],
  );
}

void _showPrivacy(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Política de privacidad'),
        content: const Text(
          'Tus datos se guardan localmente en el dispositivo. No compartimos ni sincronizamos la información con servidores externos. '
          'Puedes exportar o borrar tus datos en cualquier momento desde la sección de cuenta.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendido'),
          ),
        ],
      );
    },
  );
}

void _confirmSignOut(BuildContext context, AppState appState) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          'Volverás a la pantalla de bienvenida. Tus datos permanecerán guardados en el dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              appState.restartOnboarding();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      );
    },
  );
}

class _SettingSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

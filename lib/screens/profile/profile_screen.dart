import 'package:flutter/material.dart';

import '../../core/alarm_sounds.dart';
import '../../core/constants.dart';
import '../../core/design_tokens.dart';
import '../../widgets/uni_supervisual.dart';
import '../../services/notification_service.dart';
import '../../state/app_state.dart';
import '../../widgets/soft_page_route.dart';
import '../../widgets/uni_card.dart';
import '../notifications/notification_center_screen.dart';
import '../tasks/task_history_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final isDarkMode = appState.themeMode == ThemeMode.dark;
    final activeProfile = appState.activeProfileSummary;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.screenHorizontal,
            12,
            DesignTokens.screenHorizontal,
            132,
          ),
          children: [
            Text('Perfil', style: theme.textTheme.displayLarge),
            const SizedBox(height: 6),
            Text(
              'Tu cuenta, recordatorios y preferencias en un solo lugar.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _ProfileHeroCard(appState: appState),
            const SizedBox(height: 28),
            const _ProfileSectionHeader(
              title: 'Preferencias',
              subtitle: 'Apariencia, alertas y pequeños ajustes cotidianos.',
            ),
            const SizedBox(height: 10),
            UniCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _SettingSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Apariencia',
                    subtitle: isDarkMode
                        ? 'Modo oscuro activo'
                        : 'Modo claro activo',
                    value: isDarkMode,
                    onChanged: (value) => appState.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    ),
                  ),
                  const Divider(),
                  _SettingTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notificaciones y alertas',
                    subtitle: 'Permisos y automatización',
                    onTap: () => _openNotificationSettings(context, appState),
                  ),
                  const Divider(),
                  _SettingTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Centro de recordatorios',
                    subtitle: 'Consulta próximos avisos',
                    onTap: () => Navigator.of(context).push(
                      SoftPageRoute(
                        builder: (_) => const NotificationCenterScreen(),
                      ),
                    ),
                  ),
                  const Divider(),
                  _SettingTile(
                    icon: Icons.history_rounded,
                    title: 'Historial de tiempo',
                    subtitle: 'Sesiones y foco acumulado',
                    onTap: () => Navigator.of(context).push(
                      SoftPageRoute(builder: (_) => const TaskHistoryScreen()),
                    ),
                  ),
                  const Divider(),
                  _SettingTile(
                    icon: Icons.music_note_outlined,
                    title: 'Sonidos de alarma',
                    subtitle: 'Actual: ${appState.alarmSound}',
                    onTap: () => _openSoundPicker(context, appState),
                  ),
                  const Divider(),
                  _SettingSwitchTile(
                    icon: Icons.favorite_border_rounded,
                    title: 'Mensajes de ánimo',
                    subtitle: 'Pequeños recordatorios para sostener el ritmo',
                    value: appState.motivationalMessages,
                    onChanged: (_) => appState.toggleMotivationMessages(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _ProfileSectionHeader(
              title: 'Cuenta y soporte',
              subtitle: activeProfile == null
                  ? 'Perfiles, privacidad y ayuda esencial.'
                  : 'Activo ahora: ${activeProfile.name}',
            ),
            const SizedBox(height: 10),
            UniCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _SettingTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Gestionar perfiles',
                    subtitle: 'Cambiar o crear perfiles de estudio',
                    onTap: () => _openAccountManager(context, appState),
                  ),
                  const Divider(),
                  _SettingTile(
                    icon: Icons.settings_outlined,
                    title: 'Ajustes avanzados',
                    subtitle: 'IA de voz, copias de seguridad y datos',
                    onTap: () => Navigator.of(context).push(
                      SoftPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  const Divider(),
                  _SettingTile(
                    icon: Icons.info_outline,
                    title: 'Acerca de UniThrive',
                    onTap: () => _showAbout(context),
                  ),
                  const Divider(),
                  _SettingTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Política de privacidad',
                    onTap: () => _showPrivacy(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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

class _ProfileHeroCard extends StatelessWidget {
  final AppState appState;

  const _ProfileHeroCard({required this.appState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activeProfile = appState.activeProfileSummary;

    return UniCard(
      radius: 32,
      color: scheme.primaryContainer.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfilePill(
            icon: Icons.person_rounded,
            label: activeProfile == null
                ? 'Perfil principal'
                : 'Perfil activo: ${activeProfile.name}',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _initials(appState.userName),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appState.userName, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      appState.userEmail.isEmpty
                          ? 'Sin correo configurado'
                          : appState.userEmail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(
                          alpha: 0.78,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                label:
                    'Nivel ${appState.level}, ${appState.xpProgressPercent.round()}% al siguiente nivel',
                child: UniRingProgress(
                  progress: appState.xpProgressPercent / 100,
                  size: 76,
                  progressColor: scheme.primary,
                  trackColor: scheme.onPrimaryContainer.withValues(alpha: 0.14),
                  center: Text(
                    '${appState.level}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Tu espacio ya está configurado para estudiar con menos fricción y más claridad.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroInfoChip(
                label: 'Tema',
                value: appState.themeMode == ThemeMode.dark
                    ? 'Oscuro'
                    : 'Claro',
              ),
              _HeroInfoChip(
                label: 'Racha',
                value: '${appState.streakDays} días',
              ),
              _HeroInfoChip(label: 'Nivel', value: '${appState.level}'),
              _HeroInfoChip(
                label: 'Perfiles',
                value: '${appState.profiles.length}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  const _ProfileSectionHeader({required this.title, required this.subtitle});

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

class _HeroInfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _HeroInfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 250),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
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
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      onTap: onTap,
      leading: _TileIcon(icon: icon),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: theme.colorScheme.onSurfaceVariant,
      ),
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
            return _AdaptiveSheetBody(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _ProfileSheetHeader(
                    'Notificaciones y alertas',
                    'Activa o desactiva los recordatorios inteligentes. Puedes volver a solicitar permisos desde el sistema cuando lo necesites.',
                  ),
                  UniCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    radius: 28,
                    child: Column(
                      children: [
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
                        const Divider(),
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
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Anticipación de recordatorios'),
                          subtitle: Text(
                            'Te avisamos ${appState.reminderLeadMinutes} min antes',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              _showReminderLeadPicker(context, appState),
                        ),
                        const Divider(),
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
                      ],
                    ),
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
              ),
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
            return _AdaptiveSheetBody(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ProfileSheetHeader(
                    'Perfiles de estudio',
                    'Cambia de entorno o crea un perfil separado para otra etapa de estudio.',
                  ),
                  UniCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    radius: 28,
                    child: Column(
                      children: profiles
                          .map(
                            (profile) => Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    profile.id == activeId
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  title: Text(
                                    profile.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: profile.email.isEmpty
                                      ? null
                                      : Text(
                                          profile.email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                  trailing:
                                      profile.id == activeId ||
                                          profiles.length == 1
                                      ? null
                                      : IconButton(
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                          onPressed: () async {
                                            final confirmed =
                                                await showDialog<bool>(
                                                  context: context,
                                                  builder: (dialogContext) =>
                                                      AlertDialog(
                                                        title: const Text(
                                                          'Eliminar perfil',
                                                        ),
                                                        content: Text(
                                                          '¿Seguro que quieres eliminar el perfil "${profile.name}"? Esta acción no se puede deshacer.',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  dialogContext,
                                                                ).pop(false),
                                                            child: const Text(
                                                              'Cancelar',
                                                            ),
                                                          ),
                                                          FilledButton(
                                                            style: FilledButton.styleFrom(
                                                              backgroundColor:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .error,
                                                            ),
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                  dialogContext,
                                                                ).pop(true),
                                                            child: const Text(
                                                              'Eliminar',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );
                                            if (confirmed != true) return;
                                            appState.deleteUserProfile(
                                              profile.id,
                                            );
                                            setSheetState(() {});
                                          },
                                        ),
                                  onTap: () {
                                    appState.switchUserProfile(profile.id);
                                    setSheetState(() {});
                                  },
                                ),
                                if (profile != profiles.last) const Divider(),
                              ],
                            ),
                          )
                          .toList(),
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
              ),
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
        scrollable: true,
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
  final options = AlarmSounds.options;
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final maxHeight = MediaQuery.of(sheetContext).size.height * 0.7;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: ListView(
              shrinkWrap: true,
              children: [
                const _ProfileSheetHeader(
                  'Sonidos de alarma',
                  'Elige un tono simple y reconocible para tus sesiones.',
                ),
                UniCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  radius: 28,
                  child: Column(
                 children: options
                     .map(
                       (sound) => Column(
                         children: [
                           ListTile(
                             contentPadding: EdgeInsets.zero,
                             title: Text(sound.label),
                             trailing: sound.label == appState.alarmSound
                                 ? Icon(
                                     Icons.check,
                                     color: Theme.of(
                                       sheetContext,
                                     ).colorScheme.primary,
                                   )
                                 : null,
                             onTap: () {
                               appState.setAlarmSound(sound.label);
                               Navigator.of(sheetContext).pop();
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text(
                                     'Sonido seleccionado: ${sound.label}',
                                   ),
                                 ),
                               );
                             },
                           ),
                           if (sound != options.last) const Divider(),
                         ],
                       ),
                     )
                     .toList(),
                  ),
                ),
              ],
            ),
          ),
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
      final maxHeight = MediaQuery.of(sheetContext).size.height * 0.7;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: ListView(
              shrinkWrap: true,
              children: [
                const _ProfileSheetHeader(
                  'Anticipación de recordatorios',
                  'Define cuánto margen necesitas antes de una tarea o clase.',
                ),
                UniCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  radius: 28,
                  child: Column(
                    children: options
                        .map(
                          (minutes) => Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Recordar $minutes min antes'),
                                trailing:
                                    minutes == appState.reminderLeadMinutes
                                    ? Icon(
                                        Icons.check,
                                        color: Theme.of(
                                          sheetContext,
                                        ).colorScheme.primary,
                                      )
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
                              if (minutes != options.last) const Divider(),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _showAbout(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'UniThrive',
    applicationVersion: Constants.appVersion,
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
        scrollable: true,
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
        scrollable: true,
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: _TileIcon(icon: icon),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final IconData icon;

  const _TileIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: theme.colorScheme.primary, size: 20),
    );
  }
}

class _ProfileSheetHeader extends StatelessWidget {
  const _ProfileSheetHeader(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 5,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _AdaptiveSheetBody extends StatelessWidget {
  final Widget child;

  const _AdaptiveSheetBody({required this.child});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.82;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(child: child),
      ),
    );
  }
}

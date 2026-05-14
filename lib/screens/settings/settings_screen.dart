import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/design_tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/uni_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final theme = Theme.of(context);
    final scalePercent = '${(appState.textScale * 100).round()}%';

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
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 8),
            Text('Ajustes', style: theme.textTheme.displayLarge),
            const SizedBox(height: 6),
            Text(
              'Personaliza cómo se ve, suena y protege tu espacio de estudio.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _SettingsHeroCard(appState: appState),
            const SizedBox(height: 28),
            const _SettingsSectionHeader(
              title: 'Datos',
              subtitle: 'Respaldo, restauración y continuidad local.',
            ),
            const SizedBox(height: 10),
            UniCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _SettingsActionTile(
                    icon: Icons.backup_outlined,
                    title: 'Exportar datos',
                    subtitle: 'Guardar copia de seguridad',
                    onTap: () => _exportData(context, appState),
                  ),
                  const Divider(),
                  _SettingsActionTile(
                    icon: Icons.restore_rounded,
                    title: 'Importar datos',
                    subtitle: 'Restaurar desde archivo',
                    onTap: () => _importData(context, appState),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SettingsSectionHeader(
              title: 'Apariencia',
              subtitle: 'Color, lectura y comodidad visual.',
            ),
            const SizedBox(height: 10),
            UniCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _SettingsSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Modo oscuro',
                    subtitle: 'Colores suaves para la noche',
                    value: appState.themeMode == ThemeMode.dark,
                    onChanged: (value) => appState.setThemeMode(
                      value ? ThemeMode.dark : ThemeMode.light,
                    ),
                  ),
                  const Divider(),
                  _SettingsSliderTile(
                    icon: Icons.text_fields_rounded,
                    title: 'Tamaño del texto',
                    subtitle: 'Ajusta la lectura en toda la app',
                    valueLabel: scalePercent,
                    value: appState.textScale,
                    min: 1.0,
                    max: 1.3,
                    divisions: 3,
                    onChanged: appState.setTextScale,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SettingsSectionHeader(
              title: 'Notificaciones',
              subtitle: 'Qué te avisa y con cuánta anticipación.',
            ),
            const SizedBox(height: 10),
            UniCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _SettingsSwitchTile(
                    icon: Icons.notifications_outlined,
                    title: 'Recordatorios de tareas',
                    subtitle: 'Notificar antes de las tareas',
                    value: appState.taskRemindersEnabled,
                    onChanged: appState.setTaskReminders,
                  ),
                  const Divider(),
                  _SettingsSwitchTile(
                    icon: Icons.school_outlined,
                    title: 'Recordatorios de clases',
                    subtitle: 'Notificar antes de las clases',
                    value: appState.classRemindersEnabled,
                    onChanged: appState.setClassReminders,
                  ),
                  const Divider(),
                  _SettingsSwitchTile(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Mensajes motivacionales',
                    subtitle: 'Recibir consejos de la mascota',
                    value: appState.motivationalMessages,
                    onChanged: appState.setMotivationalMessages,
                  ),
                  const Divider(),
                  _SettingsActionTile(
                    icon: Icons.access_time_rounded,
                    title: 'Anticipación de recordatorios',
                    subtitle: '${appState.reminderLeadMinutes} minutos antes',
                    value: '${appState.reminderLeadMinutes} min',
                    onTap: () => _showReminderLeadDialog(context, appState),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SettingsSectionHeader(
              title: 'Voz e IA',
              subtitle:
                  'Dictado local con mejora opcional vía endpoint seguro.',
            ),
            const SizedBox(height: 10),
            UniCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _SettingsActionTile(
                    icon: Icons.hub_outlined,
                    title: 'Endpoint IA seguro',
                    subtitle: appState.voiceAiEndpointUrl.isEmpty
                        ? 'Sin configurar. La app seguirá usando parser local.'
                        : _voiceAiEndpointSubtitle(appState.voiceAiEndpointUrl),
                    value: _voiceAiEndpointBadge(appState.voiceAiEndpointUrl),
                    onTap: () => _showVoiceAiDialog(context, appState),
                  ),
                  const Divider(),
                  _SettingsSwitchTile(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Mejorar dictado con IA',
                    subtitle: appState.voiceAiEndpointUrl.isEmpty
                        ? 'Configura primero un endpoint antes de activarlo.'
                        : 'Refina frases complejas sin exponer una API key en la app.',
                    value: appState.voiceAiEnabled,
                    onChanged: (value) {
                      if (value && appState.voiceAiEndpointUrl.isEmpty) {
                        _showVoiceAiDialog(
                          context,
                          appState,
                          enableAfterSave: true,
                        );
                        return;
                      }
                      appState.setVoiceAiEnabled(value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SettingsSectionHeader(
              title: 'Sonido',
              subtitle: 'Cómo se siente cada alarma o aviso.',
            ),
            const SizedBox(height: 10),
            UniCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _SettingsActionTile(
                icon: Icons.volume_up_outlined,
                title: 'Sonido de alarma',
                subtitle: 'Actual: ${appState.alarmSound}',
                value: appState.alarmSound,
                onTap: () => _showAlarmSoundDialog(context, appState),
              ),
            ),
            const SizedBox(height: 24),
            const _SettingsSectionHeader(
              title: 'Avanzado',
              subtitle: 'Controles sensibles para reiniciar o limpiar.',
            ),
            const SizedBox(height: 10),
            UniCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _SettingsActionTile(
                    icon: Icons.restart_alt_rounded,
                    title: 'Restaurar valores predeterminados',
                    subtitle: 'Mantiene tus tareas y proyectos',
                    accentColor: Colors.orange,
                    onTap: () => _confirmResetSettings(context, appState),
                  ),
                  const Divider(),
                  _SettingsActionTile(
                    icon: Icons.delete_forever_outlined,
                    title: 'Borrar todos los datos',
                    subtitle: 'Elimina TODAS las tareas y proyectos',
                    accentColor: theme.colorScheme.error,
                    onTap: () => _confirmDeleteAllData(context, appState),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SettingsSectionHeader(
              title: 'Acerca de',
              subtitle: 'Información de versión y tecnología.',
            ),
            const SizedBox(height: 10),
            UniCard(
              radius: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SettingsIcon(icon: Icons.info_outline_rounded),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'UniThrive 1.0.0',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SettingsMetaRow(
                    label: 'Versión de la app',
                    value: 'UniThrive 1.0.0',
                  ),
                  const SizedBox(height: 10),
                  const _SettingsMetaRow(
                    label: 'Desarrollado con',
                    value: 'Flutter y experiencia local',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== EXPORT DATA ====================
  Future<void> _exportData(BuildContext context, AppState appState) async {
    try {
      // Get app data as JSON
      final jsonData = appState.exportToJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);

      // On mobile we create a temporary file and let the share sheet handle
      // the final destination. This avoids scoped-storage issues on Android.
      final Directory directory = Platform.isAndroid || Platform.isIOS
          ? await getTemporaryDirectory()
          : await getApplicationDocumentsDirectory();

      // Create filename with timestamp
      final timestamp = DateTime.now()
          .toIso8601String()
          .split('.')[0]
          .replaceAll(':', '-');
      final filename = 'unithrive_backup_$timestamp.json';
      final file = File('${directory.path}/$filename');

      // Write file
      await file.writeAsString(jsonString);

      if (context.mounted) {
        // Show success with option to share
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: const Text('✅ Exportación exitosa'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Platform.isAndroid || Platform.isIOS
                      ? 'Tu copia de seguridad está lista para compartir o guardar desde otra app:'
                      : 'Tu copia de seguridad se guardó en:',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    file.path,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Share.shareXFiles([
                    XFile(file.path),
                  ], text: 'UniThrive Backup');
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.share),
                label: const Text('Compartir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9FCFBB),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }

  // ==================== IMPORT DATA ====================
  Future<void> _importData(BuildContext context, AppState appState) async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);

      if (context.mounted) {
        // Confirm import
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: const Text('⚠️ Confirmar importación'),
            content: const Text(
              'Esto REEMPLAZARÁ todos tus datos actuales. '
              '¿Estás seguro?\n\n'
              'Recomendación: Exporta tus datos actuales primero.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Importar'),
              ),
            ],
          ),
        );

        if (confirm == true && context.mounted) {
          await appState.importFromJson(jsonData);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Datos importados exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al importar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ==================== DIALOGS ====================
  void _showReminderLeadDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => SettingsReminderLeadDialog(appState: appState),
    );
  }

  void _showAlarmSoundDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => SettingsAlarmSoundDialog(appState: appState),
    );
  }

  void _showVoiceAiDialog(
    BuildContext context,
    AppState appState, {
    bool enableAfterSave = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => SettingsVoiceAiDialog(
        appState: appState,
        enableAfterSave: enableAfterSave,
      ),
    );
  }

  void _confirmResetSettings(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => SettingsResetDialog(appState: appState),
    );
  }

  void _confirmDeleteAllData(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => SettingsDeleteAllDataDialog(appState: appState),
    );
  }
}

String _voiceAiEndpointBadge(String endpointUrl) {
  if (endpointUrl.trim().isEmpty) {
    return 'Pendiente';
  }
  final uri = Uri.tryParse(endpointUrl.trim());
  if (uri == null || uri.host.isEmpty) {
    return 'Listo';
  }
  return uri.host;
}

String _voiceAiEndpointSubtitle(String endpointUrl) {
  final uri = Uri.tryParse(endpointUrl.trim());
  if (uri == null) {
    return 'Endpoint personalizado configurado.';
  }
  final path = uri.path.isEmpty ? '/' : uri.path;
  return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}$path';
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return UniCard(
      radius: 34,
      color: scheme.primaryContainer.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsTopChip(
            icon: Icons.tune_rounded,
            label: 'Espacio personalizado',
          ),
          const SizedBox(height: 18),
          Text(
            'Tu configuración actual está lista para acompañar tu ritmo.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tema ${appState.themeMode == ThemeMode.dark ? 'oscuro' : 'claro'}, texto en ${(appState.textScale * 100).round()}% y recordatorios ${appState.taskRemindersEnabled || appState.classRemindersEnabled ? 'activos' : 'en pausa'}.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SettingsPill(
                icon: Icons.text_fields_rounded,
                label: '${(appState.textScale * 100).round()}% texto',
              ),
              _SettingsPill(
                icon: Icons.notifications_active_outlined,
                label: '${appState.reminderLeadMinutes} min antes',
              ),
              _SettingsPill(
                icon: Icons.music_note_outlined,
                label: appState.alarmSound,
              ),
              _SettingsPill(
                icon: Icons.auto_awesome_rounded,
                label: appState.voiceAiEnabled
                    ? 'IA de voz activa'
                    : 'Voz local',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({required this.title, required this.subtitle});

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

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = accentColor ?? theme.colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 320 && value != null;
        return InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingsIcon(icon: icon, tint: tint),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: accentColor == null ? null : tint,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(subtitle!, style: theme.textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),
                    if (!stacked) ...[
                      const SizedBox(width: 12),
                      value != null
                          ? _SettingsValueBadge(label: value!, tint: tint)
                          : Icon(
                              Icons.chevron_right_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                    ],
                  ],
                ),
                if (stacked) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: _SettingsValueBadge(label: value!, tint: tint),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: _SettingsIcon(icon: icon),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }
}

class _SettingsSliderTile extends StatelessWidget {
  const _SettingsSliderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 320;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SettingsIcon(icon: icon),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(subtitle, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      if (!stacked) ...[
                        const SizedBox(width: 12),
                        _SettingsValueBadge(
                          label: valueLabel,
                          tint: theme.colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                  if (stacked) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 56),
                        child: _SettingsValueBadge(
                          label: valueLabel,
                          tint: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 58, right: 8, bottom: 8),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: valueLabel,
                onChanged: onChanged,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsMetaRow extends StatelessWidget {
  const _SettingsMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 320;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.titleSmall),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, this.tint});

  final IconData icon;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tint ?? theme.colorScheme.primary;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _SettingsTopChip extends StatelessWidget {
  const _SettingsTopChip({required this.icon, required this.label});

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
        constraints: const BoxConstraints(maxWidth: 220),
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

class _SettingsPill extends StatelessWidget {
  const _SettingsPill({required this.icon, required this.label});

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
        constraints: const BoxConstraints(maxWidth: 210),
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

class _SettingsValueBadge extends StatelessWidget {
  const _SettingsValueBadge({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 110),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(color: tint),
        ),
      ),
    );
  }
}

class SettingsReminderLeadDialog extends StatelessWidget {
  const SettingsReminderLeadDialog({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Anticipación de recordatorios'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [5, 10, 15, 30, 60].map((minutes) {
            final isSelected = appState.reminderLeadMinutes == minutes;
            return ListTile(
              title: Text('$minutes minutos antes'),
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF9FCFBB) : Colors.grey,
              ),
              onTap: () {
                appState.setReminderLeadMinutes(minutes);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class SettingsAlarmSoundDialog extends StatelessWidget {
  const SettingsAlarmSoundDialog({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    const sounds = ['Clásico', 'Suave', 'Digital', 'Campanas', 'Silencioso'];

    return AlertDialog(
      scrollable: true,
      title: const Text('Sonido de alarma'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: sounds.map((sound) {
            final isSelected = appState.alarmSound == sound;
            return ListTile(
              title: Text(sound),
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF9FCFBB) : Colors.grey,
              ),
              onTap: () {
                appState.setAlarmSound(sound);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class SettingsVoiceAiDialog extends StatefulWidget {
  const SettingsVoiceAiDialog({
    super.key,
    required this.appState,
    this.enableAfterSave = false,
  });

  final AppState appState;
  final bool enableAfterSave;

  @override
  State<SettingsVoiceAiDialog> createState() => _SettingsVoiceAiDialogState();
}

class _SettingsVoiceAiDialogState extends State<SettingsVoiceAiDialog> {
  late final TextEditingController _endpointController;
  late final TextEditingController _tokenController;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _endpointController = TextEditingController(
      text: widget.appState.voiceAiEndpointUrl,
    );
    _tokenController = TextEditingController(
      text: widget.appState.voiceAiProxyToken,
    );
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Endpoint IA para voz'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La app solo guarda la URL de tu proxy y, si quieres, un token de ese proxy. No pegues aquí una API key de OpenAI.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _endpointController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL del endpoint',
                hintText: 'http://10.0.2.2:8787/parse',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _tokenController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Token del proxy (opcional)',
                hintText: 'Bearer del proxy, no la API key real',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Si borras la URL, la mejora con IA quedará desactivada y el dictado seguirá funcionando en modo local.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_validationMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _validationMessage!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }

  void _save() {
    final endpoint = _endpointController.text.trim();
    final token = _tokenController.text.trim();

    if (endpoint.isNotEmpty) {
      final uri = Uri.tryParse(endpoint);
      final isValid =
          uri != null &&
          uri.isAbsolute &&
          (uri.scheme == 'http' || uri.scheme == 'https');
      if (!isValid) {
        setState(() {
          _validationMessage =
              'Usa una URL absoluta válida, por ejemplo http://10.0.2.2:8787/parse o https://tu-dominio/parse.';
        });
        return;
      }
    }

    widget.appState.updateVoiceAiConfig(
      endpointUrl: endpoint,
      proxyToken: token,
    );
    if (widget.enableAfterSave && endpoint.isNotEmpty) {
      widget.appState.setVoiceAiEnabled(true);
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          endpoint.isEmpty
              ? 'Se desactivó el endpoint IA. El dictado seguirá en modo local.'
              : 'Configuración IA guardada.',
        ),
      ),
    );
  }
}

class SettingsResetDialog extends StatelessWidget {
  const SettingsResetDialog({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Restaurar configuración'),
      content: const Text(
        'Esto restaurará todas las preferencias a sus valores predeterminados.\n\n'
        'Tus tareas, proyectos y progreso NO se verán afectados.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            appState.resetSettings();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuración restaurada')),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Restaurar'),
        ),
      ],
    );
  }
}

class SettingsDeleteAllDataDialog extends StatelessWidget {
  const SettingsDeleteAllDataDialog({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('⚠️ PELIGRO'),
      content: const Text(
        'Esto eliminará PERMANENTEMENTE:\n\n'
        '• Todas las tareas\n'
        '• Todos los proyectos\n'
        '• Todo el progreso y XP\n'
        '• Todos los logros\n'
        '• Historial de enfoque\n\n'
        'Esta acción NO se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            appState.deleteAllData();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Todos los datos han sido eliminados'),
                backgroundColor: Colors.red,
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('ELIMINAR TODO'),
        ),
      ],
    );
  }
}

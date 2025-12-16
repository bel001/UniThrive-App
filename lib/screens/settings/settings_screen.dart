import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ==================== DATOS ====================
          _buildSectionHeader('Datos'),
          ListTile(
            leading: const Icon(Icons.backup, color: Color(0xFF9FCFBB)),
            title: const Text('Exportar datos'),
            subtitle: const Text('Guardar copia de seguridad'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _exportData(context, appState),
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: Color(0xFF9FCFBB)),
            title: const Text('Importar datos'),
            subtitle: const Text('Restaurar desde archivo'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _importData(context, appState),
          ),
          const Divider(height: 32),

          // ==================== APARIENCIA ====================
          _buildSectionHeader('Apariencia'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode, color: Color(0xFF9FCFBB)),
            value: appState.themeMode == ThemeMode.dark,
            onChanged: (value) =>
                appState.setThemeMode(value ? ThemeMode.dark : ThemeMode.light),
            title: const Text('Modo oscuro'),
            subtitle: const Text('Colores suaves para la noche'),
          ),
          ListTile(
            leading: const Icon(Icons.text_fields, color: Color(0xFF9FCFBB)),
            title: const Text('Tamaño del texto'),
            subtitle: Slider(
              value: appState.textScale,
              min: 1.0,
              max: 1.3,
              divisions: 3,
              label: '${(appState.textScale * 100).round()}%',
              onChanged: appState.setTextScale,
              activeColor: const Color(0xFF9FCFBB),
            ),
            trailing: Text(
              '${(appState.textScale * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Divider(height: 32),

          // ==================== NOTIFICACIONES ====================
          _buildSectionHeader('Notificaciones'),
          SwitchListTile(
            secondary: const Icon(
              Icons.notifications,
              color: Color(0xFF9FCFBB),
            ),
            value: appState.taskRemindersEnabled,
            onChanged: appState.setTaskReminders,
            title: const Text('Recordatorios de tareas'),
            subtitle: const Text('Notificar antes de las tareas'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.school, color: Color(0xFF9FCFBB)),
            value: appState.classRemindersEnabled,
            onChanged: appState.setClassReminders,
            title: const Text('Recordatorios de clases'),
            subtitle: const Text('Notificar antes de las clases'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.star, color: Color(0xFF9FCFBB)),
            value: appState.motivationalMessages,
            onChanged: appState.setMotivationalMessages,
            title: const Text('Mensajes motivacionales'),
            subtitle: const Text('Recibir consejos de la mascota'),
          ),
          ListTile(
            leading: const Icon(Icons.access_time, color: Color(0xFF9FCFBB)),
            title: const Text('Anticipación de recordatorios'),
            subtitle: Text('${appState.reminderLeadMinutes} minutos antes'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showReminderLeadDialog(context, appState),
          ),
          const Divider(height: 32),

          // ==================== SONIDO ====================
          _buildSectionHeader('Sonido'),
          ListTile(
            leading: const Icon(Icons.volume_up, color: Color(0xFF9FCFBB)),
            title: const Text('Sonido de alarma'),
            subtitle: Text(appState.alarmSound),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showAlarmSoundDialog(context, appState),
          ),
          const Divider(height: 32),

          // ==================== AVANZADO ====================
          _buildSectionHeader('Avanzado'),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.orange),
            title: const Text('Restaurar valores predeterminados'),
            subtitle: const Text('Mantiene tus tareas y proyectos'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _confirmResetSettings(context, appState),
          ),
          ListTile(
            leading: const Icon(Icons.warning, color: Colors.red),
            title: const Text('Borrar todos los datos'),
            subtitle: const Text('Elimina TODAS las tareas y proyectos'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _confirmDeleteAllData(context, appState),
          ),
          const Divider(height: 32),

          // ==================== ACERCA DE ====================
          _buildSectionHeader('Acerca de'),
          ListTile(
            leading: const Icon(Icons.info, color: Color(0xFF9FCFBB)),
            title: const Text('Versión de la app'),
            subtitle: const Text('UniThrive 1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.code, color: Color(0xFF9FCFBB)),
            title: const Text('Desarrollado con'),
            subtitle: const Text('Flutter & ❤️'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9FCFBB),
          letterSpacing: 1,
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

      // Get downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

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
            title: const Text('✅ Exportación exitosa'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tu copia de seguridad se guardó en:'),
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
      builder: (context) => AlertDialog(
        title: const Text('Anticipación de recordatorios'),
        content: Column(
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

  void _showAlarmSoundDialog(BuildContext context, AppState appState) {
    final sounds = ['Clásico', 'Suave', 'Digital', 'Campanas', 'Silencioso'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sonido de alarma'),
        content: Column(
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

  void _confirmResetSettings(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );
  }

  void _confirmDeleteAllData(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );
  }
}

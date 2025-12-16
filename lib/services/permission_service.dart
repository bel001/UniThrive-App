import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  static Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  static Future<bool> requestAllPermissions(BuildContext context) async {
    final results = <String, bool>{};

    // Request notification permission
    final notif = await requestNotificationPermission();
    results['Notificaciones'] = notif;

    // Request photos permission for image picker
    final photos = await requestPhotosPermission();
    results['Fotos'] = photos;

    // Show summary if any were denied
    final denied = results.entries.where((e) => !e.value).toList();
    if (denied.isNotEmpty && context.mounted) {
      _showPermissionSummary(context, denied);
    }

    return denied.isEmpty;
  }

  static void _showPermissionSummary(
    BuildContext context,
    List<MapEntry<String, bool>> denied,
  ) {
    final deniedNames = denied.map((e) => e.key).join(', ');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos necesarios'),
        content: Text(
          'Los siguientes permisos fueron denegados: $deniedNames.\n\n'
          'Algunas funciones pueden no estar disponibles. '
          'Puedes cambiar esto en la configuración del sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Abrir configuración'),
          ),
        ],
      ),
    );
  }

  static Future<void> showPermissionRationale(
    BuildContext context,
    String permission,
    String reason,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permiso: $permission'),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

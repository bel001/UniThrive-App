/// Catálogo único de sonidos de alarma.
/// Perfil y Ajustes usan esta misma lista; cada entrada mapea a un asset real
/// que se reproduce vía el paquete `alarm` (assetAudioPath).
class AlarmSoundOption {
  final String label;
  final String assetPath;

  const AlarmSoundOption(this.label, this.assetPath);
}

class AlarmSounds {
  AlarmSounds._();

  static const List<AlarmSoundOption> options = [
    AlarmSoundOption('Clásico', 'assets/alarm/clasico.wav'),
    AlarmSoundOption('Suave', 'assets/alarm/suave.wav'),
    AlarmSoundOption('Digital', 'assets/alarm/digital.wav'),
    AlarmSoundOption('Olas', 'assets/alarm/olas.wav'),
    AlarmSoundOption('Campanas', 'assets/alarm/campanas.wav'),
    AlarmSoundOption('Minimal', 'assets/alarm/minimal.wav'),
    AlarmSoundOption('Silencioso', 'assets/alarm/silencioso.wav'),
  ];

  static const String defaultLabel = 'Clásico';

  static AlarmSoundOption byLabel(String label) {
    return options.firstWhere(
      (option) => option.label == label,
      orElse: () => options.first,
    );
  }

  /// Normaliza etiquetas antiguas ('Campana' → 'Campanas').
  static String normalizeLabel(String? label) {
    if (label == null || label.isEmpty) return defaultLabel;
    if (label == 'Campana') return 'Campanas';
    for (final option in options) {
      if (option.label == label) return label;
    }
    return defaultLabel;
  }

  /// Resuelve la ruta de asset para una etiqueta guardada,
  /// aceptando también rutas de asset directas.
  static String? assetPathFor(String? labelOrPath) {
    if (labelOrPath == null || labelOrPath.isEmpty) {
      return byLabel(defaultLabel).assetPath;
    }
    if (labelOrPath.startsWith('assets/')) return labelOrPath;
    return byLabel(normalizeLabel(labelOrPath)).assetPath;
  }
}

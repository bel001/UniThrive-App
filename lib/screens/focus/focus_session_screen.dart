import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/soft_page_route.dart';
import '../../widgets/uni_primary_button.dart';
import 'focus_timer_screen.dart';

class FocusSessionScreen extends StatefulWidget {
  final String taskLabel;
  const FocusSessionScreen({super.key, required this.taskLabel});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> {
  late List<_PrepStep> _steps;

  @override
  void initState() {
    super.initState();
    _steps = [
      const _PrepStep(
        title: 'Material listo',
        subtitle: 'Cuaderno, laptop y links abiertos.',
      ),
      const _PrepStep(
        title: 'Distracciones fuera',
        subtitle: 'Modo avión o silenciar apps que te distraen.',
      ),
      const _PrepStep(
        title: 'Recompensa definida',
        subtitle: 'Elige qué te darás al terminar (café, serie, paseo).',
      ),
    ];
  }

  bool get _readyToStart => _steps.every((step) => step.checked);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF050714)
        : const Color(0xFFF7F6FF);
    final panelColor = isDark ? const Color(0xFF1C2341) : Colors.white;
    final mutedColor = isDark
        ? const Color(0xFFCBD5F5)
        : const Color(0xFF475569);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.close, color: isDark ? Colors.white : accent),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: panelColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: accent, width: 6),
                      ),
                      child: Icon(
                        Icons.access_time,
                        size: 64,
                        color: isDark ? Colors.white : accent,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '¡HORA DE ENFOCARSE!',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tu sesión de ${Constants.focusDuration.inMinutes} minutos de “${widget.taskLabel}” está lista.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedColor),
                    ),
                    const SizedBox(height: 24),
                    _buildChecklistCard(
                      panelColor,
                      mutedColor,
                      accent,
                      isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  IgnorePointer(
                    ignoring: !_readyToStart,
                    child: Opacity(
                      opacity: _readyToStart ? 1 : 0.4,
                      child: UniPrimaryButton(
                        label: 'Empezar sesión',
                        backgroundColor: accent,
                        icon: Icons.play_arrow,
                        onPressed: _launchFocusTimer,
                      ),
                    ),
                  ),
                  if (!_readyToStart)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Marca los pasos para activar el modo enfoque.',
                        style: TextStyle(color: mutedColor),
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(
                      'Posponer 5 min',
                      style: TextStyle(color: mutedColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard(
    Color panelColor,
    Color mutedColor,
    Color accent,
    Color textColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Checklist de activación',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ..._steps.asMap().entries.map(
            (entry) => CheckboxListTile(
              value: entry.value.checked,
              onChanged: (value) => _toggleStep(entry.key, value ?? false),
              activeColor: accent,
              checkboxShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.zero,
              title: Text(
                entry.value.title,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                entry.value.subtitle,
                style: TextStyle(color: mutedColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleStep(int index, bool checked) {
    setState(() {
      _steps[index] = _steps[index].copyWith(checked: checked);
    });
  }

  void _launchFocusTimer() {
    Navigator.of(context).pushReplacement(
      SoftPageRoute(
        builder: (_) => FocusTimerScreen(focusLabel: widget.taskLabel),
      ),
    );
  }
}

class _PrepStep {
  final String title;
  final String subtitle;
  final bool checked;
  const _PrepStep({
    required this.title,
    required this.subtitle,
    this.checked = false,
  });

  _PrepStep copyWith({bool? checked}) => _PrepStep(
    title: title,
    subtitle: subtitle,
    checked: checked ?? this.checked,
  );
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/design_tokens.dart';
import '../models/schedule.dart';
import '../models/voice_schedule_draft.dart';
import '../services/voice_ai_parse_service.dart';
import '../services/voice_schedule_parser.dart';
import '../services/voice_task_capture_service.dart';
import '../state/app_state.dart';
import 'uni_card.dart';
import 'uni_primary_button.dart';

class VoiceScheduleSheet extends StatefulWidget {
  final DateTime? referenceDay;
  final VoiceAiParseService aiParseService;
  final VoiceTaskCaptureService captureService;
  final VoiceScheduleParser parser;

  VoiceScheduleSheet({
    super.key,
    this.referenceDay,
    VoiceAiParseService? aiParseService,
    VoiceTaskCaptureService? captureService,
    VoiceScheduleParser? parser,
  }) : aiParseService = aiParseService ?? VoiceAiParseService.instance,
       captureService = captureService ?? VoiceTaskCaptureService.instance,
       parser = parser ?? const VoiceScheduleParser();

  @override
  State<VoiceScheduleSheet> createState() => _VoiceScheduleSheetState();
}

class _VoiceScheduleSheetState extends State<VoiceScheduleSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late VoiceScheduleDraft _draft;

  String _statusText =
      'Dicta algo como “Mi clase de Física es lunes y miércoles de 8 a 10 am en aula B203 hasta julio”.';
  String? _captureError;
  bool _isListening = false;
  bool _isSaving = false;
  bool _isEnhancingWithAi = false;
  double _soundLevel = 0;
  String? _aiStatusText;
  String? _lastAiTranscript;

  DateTime get _referenceDate {
    final source = widget.referenceDay ?? DateTime.now();
    final now = DateTime.now();
    return DateTime(
      source.year,
      source.month,
      source.day,
      now.hour,
      now.minute,
    );
  }

  @override
  void initState() {
    super.initState();
    _draft = VoiceScheduleDraft.empty(referenceTime: _referenceDate);
    _titleController = TextEditingController(text: _draft.title);
    _locationController = TextEditingController(text: _draft.location);
  }

  @override
  void dispose() {
    widget.captureService.stopListening();
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateProvider.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final level = (_soundLevel.abs() / 50).clamp(0.0, 1.0);
    final aiEnabled =
        appState.voiceAiEnabled && appState.voiceAiEndpointUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.85),
          ),
      padding: EdgeInsets.only(
        left: DesignTokens.screenHorizontal,
        right: DesignTokens.screenHorizontal,
        top: 18,
        bottom: bottomInset + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agregar horario por voz',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Dicta el nombre de la clase, los días, el rango horario y, si quieres, hasta cuándo se repite.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: _isListening
                        ? 'Detener dictado'
                        : 'Iniciar dictado',
                    onPressed: _isSaving ? null : _toggleListening,
                    icon: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              UniCard(
                radius: 26,
                padding: const EdgeInsets.all(18),
                color: theme.colorScheme.surfaceContainerLow,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final chip = _ScheduleStatusChip(
                          label: _isListening ? 'Escuchando' : 'Vista previa',
                          icon: _isListening
                              ? Icons.graphic_eq
                              : Icons.auto_awesome_rounded,
                          tone: _isListening
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          foregroundColor: _isListening
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        );
                        if (constraints.maxWidth < 260) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              chip,
                              const SizedBox(height: 10),
                              Text(
                                _statusText,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            chip,
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _isListening ? level : 0,
                        minHeight: 8,
                        color: theme.colorScheme.primary,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        _draft.hasTranscript
                            ? _draft.transcript
                            : 'Todavía no hay audio procesado. Habla de forma natural y en una sola frase para que la serie quede bien armada.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _draft.hasTranscript
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (_captureError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _captureError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    if (_isEnhancingWithAi || _aiStatusText != null) ...[
                      const SizedBox(height: 12),
                      _ScheduleAssistBanner(
                        icon: _isEnhancingWithAi
                            ? Icons.auto_awesome_rounded
                            : aiEnabled
                            ? Icons.cloud_done_outlined
                            : Icons.info_outline_rounded,
                        text:
                            _aiStatusText ??
                            'Se mantendrá la interpretación local.',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _titleController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Clase o curso',
                  hintText: 'Ej. Física II',
                  prefixIcon: Icon(Icons.school_rounded),
                ),
                onChanged: (value) {
                  _draft = _draft.copyWith(title: value);
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Aula o ubicación',
                  hintText: 'Ej. Aula B203',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                onChanged: (value) {
                  _draft = _draft.copyWith(location: value);
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              Text('Días de clase', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  const labels = ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'];
                  final weekday = index + 1;
                  final selected = _draft.weekDays.contains(weekday);
                  return ChoiceChip(
                    label: Text(labels[index]),
                    selected: selected,
                    onSelected: _isSaving
                        ? null
                        : (_) => _toggleWeekDay(weekday),
                  );
                }),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stack = constraints.maxWidth < 360;
                  final firstDateButton = OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickFirstDate,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(
                      DateFormat('EEE d MMM', 'es').format(_draft.firstStart),
                    ),
                  );
                  final recurrenceButton = OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickRecurrenceEndDate,
                    icon: Icon(
                      _draft.recurrenceEndDate == null
                          ? Icons.repeat_rounded
                          : Icons.event_repeat_rounded,
                      size: 18,
                    ),
                    label: Text(
                      _draft.recurrenceEndDate == null
                          ? 'Sin fecha límite'
                          : DateFormat(
                              'Hasta d MMM',
                              'es',
                            ).format(_draft.recurrenceEndDate!),
                    ),
                  );

                  if (stack) {
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: firstDateButton,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: recurrenceButton,
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: firstDateButton),
                      const SizedBox(width: 12),
                      Expanded(child: recurrenceButton),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stack = constraints.maxWidth < 360;
                  final startButton = OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickStartTime,
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(
                      DateFormat('hh:mm a', 'es').format(_draft.firstStart),
                    ),
                  );
                  final endButton = OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickEndTime,
                    icon: const Icon(Icons.timer_outlined, size: 18),
                    label: Text(
                      DateFormat('hh:mm a', 'es').format(_draft.firstEnd),
                    ),
                  );

                  if (stack) {
                    return Column(
                      children: [
                        SizedBox(width: double.infinity, child: startButton),
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: endButton),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: startButton),
                      const SizedBox(width: 12),
                      Expanded(child: endButton),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _RecurrenceSummary(draft: _draft),
              if (_draft.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._draft.notes.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ScheduleInlineNote(note: note),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stack = constraints.maxWidth < 360;
                  final saveButton = IgnorePointer(
                    ignoring: !_draft.canSave || _isSaving,
                    child: Opacity(
                      opacity: _draft.canSave && !_isSaving ? 1 : 0.55,
                      child: UniPrimaryButton(
                        label: _isSaving ? 'Guardando...' : 'Guardar horario',
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: _saveSchedule,
                      ),
                    ),
                  );
                  final listenButton = OutlinedButton.icon(
                    onPressed: _isSaving ? null : _toggleListening,
                    icon: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    ),
                    label: Text(_isListening ? 'Detener' : 'Volver a dictar'),
                  );

                  if (stack) {
                    return Column(
                      children: [
                        SizedBox(width: double.infinity, child: saveButton),
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: listenButton),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: saveButton),
                      const SizedBox(width: 12),
                      Expanded(child: listenButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    )));
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await widget.captureService.stopListening();
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _statusText = _draft.hasTranscript
            ? 'Dictado detenido. Revisa la serie y guarda.'
            : 'No se capturó suficiente audio. Puedes intentarlo otra vez.';
      });
      return;
    }

    setState(() {
      _captureError = null;
      _statusText = 'Preparando micrófono...';
      _soundLevel = 0;
      _aiStatusText = null;
      _lastAiTranscript = null;
      _isEnhancingWithAi = false;
    });

    final result = await widget.captureService.startListening(
      onTranscript: (transcript, isFinal) {
        if (!mounted) return;
        final appState = AppStateProvider.of(context);
        final aiEnabled =
            appState.voiceAiEnabled && appState.voiceAiEndpointUrl.isNotEmpty;
        final parsed = widget.parser.parse(
          transcript,
          referenceTime: _referenceDate,
        );
        setState(() {
          _draft = parsed;
          _titleController.value = TextEditingValue(
            text: parsed.title,
            selection: TextSelection.collapsed(offset: parsed.title.length),
          );
          _locationController.value = TextEditingValue(
            text: parsed.location,
            selection: TextSelection.collapsed(offset: parsed.location.length),
          );
          _captureError = null;
          _statusText = isFinal
              ? aiEnabled
                    ? 'Serie lista. Intentando afinarla con IA segura.'
                    : 'Serie lista. Revisa la vista previa antes de guardar.'
              : 'Estoy preparando tu horario...';
        });
        if (isFinal) {
          _enhanceScheduleWithAi(appState: appState, transcript: transcript);
        }
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() => _soundLevel = level);
      },
      onStatusChanged: (status) {
        if (!mounted) return;
        setState(() {
          _isListening = status == 'listening';
          if (status == 'done' || status == 'notListening') {
            _statusText = _draft.hasTranscript
                ? 'Serie lista. Revisa la vista previa antes de guardar.'
                : 'El dictado terminó sin suficiente contenido.';
          }
        });
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _captureError = message;
          _isListening = false;
          _statusText = 'No pude completar el dictado.';
        });
      },
    );

    if (!mounted) return;
    if (!result.canListen) {
      setState(() {
        _captureError = result.message;
        _statusText =
            result.message ?? 'La voz no está disponible ahora mismo.';
        _isListening = false;
      });
      return;
    }

    setState(() {
      _isListening = true;
      _statusText = 'Escuchando tu horario...';
      _captureError = null;
    });
  }

  Future<void> _enhanceScheduleWithAi({
    required AppState appState,
    required String transcript,
  }) async {
    final normalizedTranscript = transcript.trim();
    if (!appState.voiceAiEnabled ||
        appState.voiceAiEndpointUrl.isEmpty ||
        normalizedTranscript.isEmpty ||
        _lastAiTranscript == normalizedTranscript) {
      return;
    }

    setState(() {
      _lastAiTranscript = normalizedTranscript;
      _isEnhancingWithAi = true;
      _aiStatusText = 'Afinando el horario con tu endpoint IA seguro...';
    });

    final outcome = await widget.aiParseService.enhanceSchedule(
      transcript: normalizedTranscript,
      referenceTime: _referenceDate,
      endpointUrl: appState.voiceAiEndpointUrl,
      proxyToken: appState.voiceAiProxyToken,
    );

    if (!mounted || _lastAiTranscript != normalizedTranscript) {
      return;
    }

    if (!outcome.hasDraft) {
      setState(() {
        _isEnhancingWithAi = false;
        _aiStatusText =
            outcome.warning ??
            'No pude mejorar el dictado. Se mantuvo la interpretación local.';
      });
      return;
    }

    final enhancedDraft = outcome.draft!;
    setState(() {
      _draft = enhancedDraft;
      _titleController.value = TextEditingValue(
        text: enhancedDraft.title,
        selection: TextSelection.collapsed(offset: enhancedDraft.title.length),
      );
      _locationController.value = TextEditingValue(
        text: enhancedDraft.location,
        selection: TextSelection.collapsed(
          offset: enhancedDraft.location.length,
        ),
      );
      _isEnhancingWithAi = false;
      _aiStatusText =
          'El horario se refinó con IA y quedó listo para revisar antes de guardar.';
    });
  }

  void _toggleWeekDay(int weekDay) {
    final nextDays = [..._draft.weekDays];
    if (nextDays.contains(weekDay)) {
      if (nextDays.length == 1) return;
      nextDays.remove(weekDay);
    } else {
      nextDays.add(weekDay);
      nextDays.sort();
    }

    final start = _realignStart(nextDays, _draft.firstStart);
    final duration = _draft.firstEnd.difference(_draft.firstStart);
    setState(() {
      _draft = _draft.copyWith(
        weekDays: nextDays,
        firstStart: start,
        firstEnd: start.add(duration),
      );
    });
  }

  Future<void> _pickFirstDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _draft.firstStart,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('es'),
    );
    if (selected == null || !mounted) return;
    final adjusted = DateTime(
      selected.year,
      selected.month,
      selected.day,
      _draft.firstStart.hour,
      _draft.firstStart.minute,
    );
    final aligned = _realignStart(_draft.weekDays, adjusted);
    final duration = _draft.firstEnd.difference(_draft.firstStart);
    setState(() {
      _draft = _draft.copyWith(
        firstStart: aligned,
        firstEnd: aligned.add(duration),
      );
    });
  }

  Future<void> _pickRecurrenceEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          _draft.recurrenceEndDate ??
          _draft.firstStart.add(const Duration(days: 120)),
      firstDate: _draft.firstStart,
      lastDate: DateTime.now().add(const Duration(days: 1000)),
      locale: const Locale('es'),
    );
    if (!mounted) return;
    if (selected == null) {
      setState(() {
        _draft = _draft.copyWith(clearRecurrenceEndDate: true);
      });
      return;
    }
    setState(() {
      _draft = _draft.copyWith(
        recurrenceEndDate: DateTime(
          selected.year,
          selected.month,
          selected.day,
        ),
      );
    });
  }

  Future<void> _pickStartTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_draft.firstStart),
    );
    if (selected == null || !mounted) return;
    final updatedStart = DateTime(
      _draft.firstStart.year,
      _draft.firstStart.month,
      _draft.firstStart.day,
      selected.hour,
      selected.minute,
    );
    final duration = _draft.firstEnd.difference(_draft.firstStart);
    setState(() {
      _draft = _draft.copyWith(
        firstStart: updatedStart,
        firstEnd: updatedStart.add(duration),
      );
    });
  }

  Future<void> _pickEndTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_draft.firstEnd),
    );
    if (selected == null || !mounted) return;
    final updatedEnd = DateTime(
      _draft.firstStart.year,
      _draft.firstStart.month,
      _draft.firstStart.day,
      selected.hour,
      selected.minute,
    );
    setState(() {
      _draft = _draft.copyWith(
        firstEnd: updatedEnd.isAfter(_draft.firstStart)
            ? updatedEnd
            : updatedEnd.add(const Duration(hours: 1)),
      );
    });
  }

  DateTime _realignStart(List<int> weekDays, DateTime reference) {
    if (weekDays.contains(reference.weekday)) {
      return reference;
    }
    final sortedDays = [...weekDays]..sort();
    final target = sortedDays.first;
    var daysAhead = target - reference.weekday;
    if (daysAhead < 0) {
      daysAhead += 7;
    }
    return reference.add(Duration(days: daysAhead));
  }

  Future<void> _saveSchedule() async {
    if (!_draft.canSave || _isSaving) return;

    setState(() {
      _isSaving = true;
      _captureError = null;
    });

    final appState = AppStateProvider.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    final weekDays = [..._draft.weekDays]..sort();
    final anchorStart = _realignStart(weekDays, _draft.firstStart);
    final duration = _draft.firstEnd.difference(_draft.firstStart);
    final recurrence = weekDays.length > 1
        ? RecurrenceType.custom
        : RecurrenceType.weekly;

    appState.addScheduleBlock(
      title: title,
      start: anchorStart,
      end: anchorStart.add(duration),
      color: const Color(0xFF85D1F7),
      location: location,
      category: ScheduleCategory.classSession,
      recurrence: recurrence,
      recurrenceEndDate: _draft.recurrenceEndDate,
      recurrenceGroupId: weekDays.length > 1
          ? 'voice-series-${DateTime.now().millisecondsSinceEpoch}'
          : null,
      customWeekDays: weekDays.length > 1 ? weekDays : null,
    );

    await widget.captureService.stopListening();

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Text(
          'Clase "$title" guardada para ${DateFormat('EEE d MMM · hh:mm a', 'es').format(anchorStart)}${location.isEmpty ? '' : ' · $location'}.',
        ),
        action: SnackBarAction(label: 'Cerrar', onPressed: () {}),
      ),
    );
  }
}

class _RecurrenceSummary extends StatelessWidget {
  final VoiceScheduleDraft draft;

  const _RecurrenceSummary({required this.draft});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayLabels = draft.weekDays.map(_weekdayLabel).join(', ');
    final endLabel = draft.recurrenceEndDate == null
        ? 'Sin fecha límite'
        : 'Hasta ${DateFormat('d MMM y', 'es').format(draft.recurrenceEndDate!)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Serie semanal', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(
            'Se repetirá ${draft.weekDays.length > 1 ? 'los ' : 'el '} $dayLabels.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(endLabel, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ScheduleStatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color tone;
  final Color foregroundColor;

  const _ScheduleStatusChip({
    required this.label,
    required this.icon,
    required this.tone,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: foregroundColor),
          ),
        ],
      ),
    );
  }
}

class _ScheduleInlineNote extends StatelessWidget {
  final String note;

  const _ScheduleInlineNote({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(note, style: theme.textTheme.bodySmall)),
      ],
    );
  }
}

class _ScheduleAssistBanner extends StatelessWidget {
  const _ScheduleAssistBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

String _weekdayLabel(int weekDay) {
  switch (weekDay) {
    case DateTime.monday:
      return 'lunes';
    case DateTime.tuesday:
      return 'martes';
    case DateTime.wednesday:
      return 'miércoles';
    case DateTime.thursday:
      return 'jueves';
    case DateTime.friday:
      return 'viernes';
    case DateTime.saturday:
      return 'sábado';
    case DateTime.sunday:
      return 'domingo';
    default:
      return 'día';
  }
}

Future<void> showVoiceScheduleSheet(
  BuildContext context, {
  DateTime? referenceDay,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => VoiceScheduleSheet(referenceDay: referenceDay),
  );
}

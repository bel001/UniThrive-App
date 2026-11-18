import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/design_tokens.dart';
import '../models/schedule.dart';
import '../models/voice_schedule_draft.dart';
import '../services/voice_schedule_parser.dart';
import '../services/voice_task_capture_service.dart';
import '../state/app_state.dart';
import 'uni_card.dart';
import 'uni_primary_button.dart';

/// Sheet de horario 100% local — parser en español inteligente con soporte multiclase,
/// fecha exacta, visualizador de audio y prevención de conflictos.
Future<void> showVoiceScheduleSheet(
  BuildContext context, {
  DateTime? referenceDay,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => VoiceScheduleSheet(referenceDay: referenceDay),
  );
}

class VoiceScheduleSheet extends StatefulWidget {
  final DateTime? referenceDay;
  final VoiceTaskCaptureService captureService;
  final VoiceScheduleParser parser;

  VoiceScheduleSheet({
    super.key,
    this.referenceDay,
    VoiceTaskCaptureService? captureService,
    VoiceScheduleParser? parser,
  })  : captureService = captureService ?? VoiceTaskCaptureService.instance,
        parser = parser ?? const VoiceScheduleParser();

  @override
  State<VoiceScheduleSheet> createState() => _VoiceScheduleSheetState();
}

class _VoiceScheduleSheetState extends State<VoiceScheduleSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  
  List<VoiceScheduleDraft> _drafts = [];
  int _activeDraftIndex = 0;

  VoiceScheduleDraft get _draft =>
      _drafts.isNotEmpty && _activeDraftIndex < _drafts.length
          ? _drafts[_activeDraftIndex]
          : VoiceScheduleDraft.empty(referenceTime: _referenceDate);

  set _draft(VoiceScheduleDraft value) {
    if (_drafts.isEmpty) {
      _drafts = [value];
      _activeDraftIndex = 0;
    } else {
      _drafts[_activeDraftIndex] = value;
    }
  }

  String _statusText =
      'Dicta algo como “Mi clase de Física es lunes y miércoles de 8 a 10 am en aula B203 hasta julio”.';
  String? _captureError;
  bool _isListening = false;
  bool _isSaving = false;
  double _soundLevel = 0;

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
    final emptyDraft = VoiceScheduleDraft.empty(referenceTime: _referenceDate);
    _drafts = [emptyDraft];
    _titleController = TextEditingController(text: emptyDraft.title);
    _locationController = TextEditingController(text: emptyDraft.location);
  }

  @override
  void dispose() {
    widget.captureService.stopListening();
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _titleController.value = TextEditingValue(
      text: _draft.title,
      selection: TextSelection.collapsed(offset: _draft.title.length),
    );
    _locationController.value = TextEditingValue(
      text: _draft.location,
      selection: TextSelection.collapsed(offset: _draft.location.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final level = (_soundLevel.abs() / 50).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.88),
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
                              'Dicta tus clases, fechas o multiclases en voz natural (ej. "Jueves 27 agosto 6 am a 8:30 pm").',
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
                          _isListening
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
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
                              label: _isListening
                                  ? 'Escuchando voz...'
                                  : 'Vista previa local',
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
                            if (constraints.maxWidth < 340) {
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
                        // Sound Wave Visualizer
                        _VoiceSoundWaveVisualizer(
                          soundLevel: level,
                          isListening: _isListening,
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
                                : 'Dicta de forma continua. Puedes incluir fechas exactas, varias clases a la vez ("Cálculo los lunes y Física los martes") o materias virtuales por Zoom.',
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
                      ],
                    ),
                  ),

                  // Batch draft tabs selector if multi-class dictation detected
                  if (_drafts.length > 1) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Detectamos ${_drafts.length} clases en tu dictado:',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_drafts.length, (index) {
                          final selected = index == _activeDraftIndex;
                          final draftTitle = _drafts[index].title;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                '${index + 1}. ${draftTitle.isEmpty ? "Clase ${index + 1}" : draftTitle}',
                              ),
                              selected: selected,
                              onSelected: (val) {
                                setState(() {
                                  _activeDraftIndex = index;
                                  _syncControllers();
                                });
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ],

                  // Conflict warning badge if overlap with user schedule
                  if (_draft.hasConflict && _draft.conflictMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _draft.conflictMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Project auto-linked badge
                  if (_draft.linkedProjectId != null) ...[
                    const SizedBox(height: 10),
                    Chip(
                      avatar: const Icon(Icons.folder_special, size: 16),
                      label: const Text('Vinculado a proyecto existente'),
                      backgroundColor:
                          theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    ),
                  ],

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
                      hintText: 'Ej. Aula B203 o Zoom',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    onChanged: (value) {
                      _draft = _draft.copyWith(location: value);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quick chips bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.more_time, size: 16),
                          label: const Text('+1 Hora'),
                          onPressed: _isSaving
                              ? null
                              : () {
                                  final newEnd =
                                      _draft.firstEnd.add(const Duration(hours: 1));
                                  setState(() {
                                    _draft = _draft.copyWith(firstEnd: newEnd);
                                  });
                                },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.date_range, size: 16),
                          label: const Text('Semestre (16 sem)'),
                          onPressed: _isSaving
                              ? null
                              : () {
                                  final endDate = _draft.firstStart
                                      .add(const Duration(days: 112));
                                  setState(() {
                                    _draft = _draft.copyWith(
                                      recurrenceEndDate: endDate,
                                    );
                                  });
                                },
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          avatar: const Icon(Icons.videocam, size: 16),
                          label: const Text('Por Zoom'),
                          onPressed: _isSaving
                              ? null
                              : () {
                                  _locationController.text = 'Por Zoom';
                                  setState(() {
                                    _draft = _draft.copyWith(location: 'Por Zoom');
                                  });
                                },
                        ),
                      ],
                    ),
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
                      final stack = constraints.maxWidth < 400;
                      final firstDateButton = OutlinedButton(
                        onPressed: _isSaving ? null : _pickFirstDate,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_outlined, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                DateFormat('EEE d MMM', 'es').format(_draft.firstStart),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                      final recurrenceButton = OutlinedButton(
                        onPressed: _isSaving ? null : _pickRecurrenceEndDate,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _draft.recurrenceEndDate == null
                                  ? Icons.repeat_rounded
                                  : Icons.event_repeat_rounded,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _draft.isSingleEvent
                                    ? 'Evento único'
                                    : _draft.recurrenceEndDate == null
                                        ? 'Sin fecha límite'
                                        : DateFormat(
                                            'Hasta d MMM',
                                            'es',
                                          ).format(_draft.recurrenceEndDate!),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                      final stack = constraints.maxWidth < 400;
                      final startButton = OutlinedButton(
                        onPressed: _isSaving ? null : _pickStartTime,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule_rounded, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                DateFormat('hh:mm a', 'es').format(_draft.firstStart),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                      final endButton = OutlinedButton(
                        onPressed: _isSaving ? null : _pickEndTime,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                DateFormat('hh:mm a', 'es').format(_draft.firstEnd),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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

                  // Actions row: Save current vs Save all
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stack = constraints.maxWidth < 400;
                      final saveButton = IgnorePointer(
                        ignoring: !_draft.canSave || _isSaving,
                        child: Opacity(
                          opacity: _draft.canSave && !_isSaving ? 1.0 : 0.5,
                          child: UniPrimaryButton(
                            label: _isSaving
                                ? 'Guardando...'
                                : _drafts.length > 1
                                    ? 'Guardar esta clase'
                                    : 'Guardar horario',
                            icon: Icons.check_circle_rounded,
                            onPressed: _saveSchedule,
                          ),
                        ),
                      );

                      if (_drafts.length > 1) {
                        final saveAllButton = OutlinedButton(
                          onPressed: _isSaving ? null : _saveAllSchedules,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.done_all_rounded, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Guardar las ${_drafts.length} clases',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );

                        if (stack) {
                          return Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: saveAllButton,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(width: double.infinity, child: saveButton),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: saveAllButton),
                            const SizedBox(width: 12),
                            Expanded(child: saveButton),
                          ],
                        );
                      }

                      return SizedBox(
                        width: double.infinity,
                        child: saveButton,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await widget.captureService.stopListening();
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _soundLevel = 0;
        _statusText = _draft.hasTranscript
            ? 'Dictado detenido. Revisa las clases y guarda.'
            : 'No se capturó suficiente audio. Puedes intentarlo otra vez.';
      });
      return;
    }

    setState(() {
      _captureError = null;
      _statusText = 'Preparando micrófono...';
      _soundLevel = 0;
    });

    final appState = AppStateProvider.of(context);

    final result = await widget.captureService.startListening(
      onTranscript: (transcript, isFinal) {
        if (!mounted) return;
        final batch = widget.parser.parseBatch(
          transcript,
          referenceTime: _referenceDate,
          existingProjects: appState.activeProjects,
          existingBlocks: appState.scheduleBlocks,
        );
        setState(() {
          _drafts = batch.isNotEmpty
              ? batch
              : [
                  widget.parser.parse(
                    transcript,
                    referenceTime: _referenceDate,
                    existingProjects: appState.activeProjects,
                    existingBlocks: appState.scheduleBlocks,
                  ),
                ];
          if (_activeDraftIndex >= _drafts.length) {
            _activeDraftIndex = 0;
          }
          _syncControllers();
          _captureError = null;
          _statusText = isFinal
              ? 'Horario listo. Revisa la vista previa antes de guardar.'
              : 'Estoy procesando tu voz...';
        });
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
                ? 'Dictado listo. Revisa la vista previa antes de guardar.'
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
    final recurrence = _draft.isSingleEvent
        ? RecurrenceType.none
        : (weekDays.length > 1 ? RecurrenceType.custom : RecurrenceType.weekly);

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

  Future<void> _saveAllSchedules() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _captureError = null;
    });

    final appState = AppStateProvider.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    var count = 0;
    for (final draft in _drafts) {
      if (!draft.canSave) continue;
      final weekDays = [...draft.weekDays]..sort();
      final anchorStart = _realignStart(weekDays, draft.firstStart);
      final duration = draft.firstEnd.difference(draft.firstStart);
      final recurrence = draft.isSingleEvent
          ? RecurrenceType.none
          : (weekDays.length > 1 ? RecurrenceType.custom : RecurrenceType.weekly);

      appState.addScheduleBlock(
        title: draft.title,
        start: anchorStart,
        end: anchorStart.add(duration),
        color: const Color(0xFF85D1F7),
        location: draft.location,
        category: ScheduleCategory.classSession,
        recurrence: recurrence,
        recurrenceEndDate: draft.recurrenceEndDate,
        recurrenceGroupId: weekDays.length > 1
            ? 'voice-series-${DateTime.now().millisecondsSinceEpoch}'
            : null,
        customWeekDays: weekDays.length > 1 ? weekDays : null,
      );
      count++;
    }

    await widget.captureService.stopListening();

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Text('$count clases agregadas a tu horario exitosamente.'),
        action: SnackBarAction(label: 'Cerrar', onPressed: () {}),
      ),
    );
  }
}

class _VoiceSoundWaveVisualizer extends StatelessWidget {
  final double soundLevel;
  final bool isListening;

  const _VoiceSoundWaveVisualizer({
    required this.soundLevel,
    required this.isListening,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(7, (index) {
          final factor = (index % 2 == 0 ? 0.6 : 1.0) * (isListening ? (soundLevel + 0.2) : 0.15);
          final barHeight = (24 * factor.clamp(0.15, 1.0)).toDouble();
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 4,
            height: barHeight,
            decoration: BoxDecoration(
              color: isListening
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          );
        }),
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
    final endLabel = draft.isSingleEvent
        ? 'Evento único'
        : (draft.recurrenceEndDate == null
            ? 'Sin fecha límite'
            : 'Hasta ${DateFormat('d MMM y', 'es').format(draft.recurrenceEndDate!)}');

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
          Text(
            draft.isSingleEvent ? 'Evento individual' : 'Serie semanal',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            draft.isSingleEvent
                ? 'Se registrará solo para este día.'
                : 'Se repetirá ${draft.weekDays.length > 1 ? 'los ' : 'el '} $dayLabels.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(endLabel, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
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
        return '';
    }
  }
}

class _ScheduleInlineNote extends StatelessWidget {
  final String note;

  const _ScheduleInlineNote({required this.note});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWarning = note.contains('⚠️');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isWarning
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.7)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        note,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isWarning
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

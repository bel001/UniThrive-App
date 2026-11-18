import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/design_tokens.dart';
import '../models/project.dart';
import '../models/schedule.dart';
import '../services/assistant_service.dart';
import '../services/schedule_ocr_service.dart';
import '../services/voice_task_capture_service.dart';
import '../state/app_state.dart';
import '../utils/platform_capabilities.dart';
import 'uni_primary_button.dart';

/// Abre el Asistente UniThrive: escucha por micrófono (o lee texto/foto),
/// detecta tareas y clases aunque vengan mezcladas e intercaladas, y las
/// propone para revisar y confirmar antes de guardar.
Future<void> showAssistantSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AssistantSheet(),
  );
}

class _Turn {
  final bool isUser;
  final String text;
  final String source;
  const _Turn({required this.isUser, required this.text, this.source = ''});
}

class _Pending {
  final AssistantCandidate candidate;
  bool saved = false;
  _Pending({required this.candidate});
}

class _AssistantSheet extends StatefulWidget {
  const _AssistantSheet();

  @override
  State<_AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<_AssistantSheet> {
  final _capture = VoiceTaskCaptureService.instance;
  final _picker = ImagePicker();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  final _turns = <_Turn>[
    const _Turn(
      isUser: false,
      text:
          'Hola, soy tu asistente. Cuéntame tu horario, tus tareas o lo que no quieres olvidar —puedes mezclar todo— y lo organizo donde corresponde. Toca el micrófono para hablarme.',
    ),
  ];
  final _pending = <_Pending>[];

  bool _isListening = false;
  bool _isWorkingPhoto = false;
  String _liveTranscript = '';
  String? _error;

  @override
  void dispose() {
    _capture.stopListening();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int get _unsavedCount => _pending.where((p) => !p.saved).length;

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ==================== Entradas ====================

  Future<void> _toggleMic() async {
    if (_isListening) {
      await _capture.stopListening();
      setState(() => _isListening = false);
      return;
    }
    if (!PlatformCapabilities.supportsVoiceInput) {
      setState(
        () => _error = 'El dictado por voz está disponible en Android e iOS.',
      );
      return;
    }
    setState(() {
      _error = null;
      _liveTranscript = '';
    });
    final result = await _capture.startListening(
      onTranscript: (transcript, isFinal) {
        if (!mounted) return;
        setState(() => _liveTranscript = transcript);
        if (isFinal && transcript.trim().isNotEmpty) {
          _capture.stopListening();
          setState(() {
            _isListening = false;
            _liveTranscript = '';
          });
          _processTurn(transcript.trim(), 'voz');
        }
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _error = message;
          _isListening = false;
        });
      },
    );
    if (!mounted) return;
    if (!result.canListen) {
      setState(() => _error = result.message);
      return;
    }
    setState(() => _isListening = true);
  }

  void _sendTypedText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _processTurn(text, 'texto');
  }

  Future<void> _pickPhotoSource() async {
    if (!PlatformCapabilities.isMobile) {
      setState(
        () => _error = 'La lectura de fotos está disponible en Android e iOS.',
      );
      return;
    }
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Foto del horario'),
        content: const Text('¿De dónde tomo la foto de tu horario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(ImageSource.camera),
            child: const Text('Cámara'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(ImageSource.gallery),
            child: const Text('Galería'),
          ),
        ],
      ),
    );
    if (source == null) return;
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file == null) return;
      setState(() {
        _isWorkingPhoto = true;
        _error = null;
      });
      final text = await ScheduleOcrService.recognizeText(file.path);
      if (!mounted) return;
      setState(() => _isWorkingPhoto = false);
      _processTurn(text, 'foto');
    } on OcrException catch (error) {
      if (!mounted) return;
      setState(() {
        _isWorkingPhoto = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isWorkingPhoto = false;
        _error = 'No pude procesar la foto. Inténtalo de nuevo.';
      });
    }
  }

  // ==================== Núcleo ====================

  void _processTurn(String text, String source) {
    final appState = AppStateProvider.of(context);
    final candidates = AssistantService.parseText(
      text,
      projects: appState.projects,
    );
    setState(() {
      _turns.add(_Turn(isUser: true, text: text, source: source));
      if (candidates.isEmpty) {
        _turns.add(
          const _Turn(
            isUser: false,
            text:
                'No detecté una tarea ni una clase ahí. Prueba con algo como “Clase de física los lunes de 8 a 10” o “Entregar el informe mañana”.',
          ),
        );
      } else {
        for (final candidate in candidates) {
          _pending.add(_Pending(candidate: candidate));
        }
        _turns.add(
          _Turn(
            isUser: false,
            text: candidates.length == 1
                ? 'Detecté esto. Revísalo y guárdalo si está bien.'
                : 'Detecté ${candidates.length} cosas. Revisa cada una y guarda las que estén bien.',
          ),
        );
      }
    });
    _scrollToEnd();
  }

  Project _resolveProject(AppState appState, String? matchedName) {
    if (matchedName != null && matchedName.trim().isNotEmpty) {
      for (final project in appState.projects) {
        if (project.name.toLowerCase() == matchedName.toLowerCase()) {
          return project;
        }
      }
    }
    return appState.getOrCreateQuickTasksProject();
  }

  Future<void> _saveCandidate(_Pending pending) async {
    if (pending.saved) return;
    final appState = AppStateProvider.of(context);
    final candidate = pending.candidate;

    if (candidate.isTask) {
      final draft = candidate.taskDraft!;
      final project = _resolveProject(appState, draft.matchedProjectName);
      appState.addTask(
        projectId: project.id,
        title: draft.title,
        dueDate: draft.dueDate,
        description: candidate.sourceText,
      );
    } else {
      final draft = candidate.scheduleDraft!;
      final weekDays = [...draft.weekDays]..sort();
      final anchorStart = _realignStart(weekDays, draft.firstStart);
      final duration = draft.firstEnd.difference(draft.firstStart);
      // El horario queda fijo: repetición semanal hasta que lo edites.
      appState.addScheduleBlock(
        title: draft.title,
        start: anchorStart,
        end: anchorStart.add(duration),
        color: const Color(0xFF85D1F7),
        location: draft.location,
        category: ScheduleCategory.classSession,
        recurrence: draft.isSingleEvent
            ? RecurrenceType.none
            : (weekDays.length > 1
                  ? RecurrenceType.custom
                  : RecurrenceType.weekly),
        recurrenceEndDate: draft.recurrenceEndDate,
        recurrenceGroupId: weekDays.length > 1
            ? 'assistant-series-${DateTime.now().millisecondsSinceEpoch}'
            : null,
        customWeekDays: weekDays.length > 1 ? weekDays : null,
      );
    }

    setState(() => pending.saved = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          candidate.isTask
              ? 'Tarea "${candidate.title}" guardada.'
              : 'Clase "${candidate.title}" fijada en tu horario.',
        ),
      ),
    );
  }

  Future<void> _saveAll() async {
    for (final pending in _pending) {
      if (!pending.saved && pending.candidate.canSave) {
        await _saveCandidate(pending);
      }
    }
  }

  DateTime _realignStart(List<int> weekDays, DateTime reference) {
    if (weekDays.contains(reference.weekday)) return reference;
    final sorted = [...weekDays]..sort();
    var daysAhead = sorted.first - reference.weekday;
    if (daysAhead < 0) daysAhead += 7;
    return reference.add(Duration(days: daysAhead));
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.cardDarkAlt : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: isDark
                        ? DesignTokens.lilac
                        : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asistente UniThrive',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Te escucho: horario, tareas e importantes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                controller: _scrollController,
                shrinkWrap: true,
                children: [
                  for (final turn in _turns) _TurnBubble(turn: turn),
                  for (final pending in _pending)
                    _CandidateCard(
                      pending: pending,
                      onSave: () => _saveCandidate(pending),
                      onDiscard: () =>
                          setState(() => _pending.remove(pending)),
                    ),
                  if (_isListening && _liveTranscript.isNotEmpty)
                    _TurnBubble(
                      turn: _Turn(isUser: true, text: _liveTranscript),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_unsavedCount >= 2)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _saveAll,
                    icon: const Icon(Icons.done_all_rounded, size: 20),
                    label: Text('Guardar todo ($_unsavedCount)'),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: 'Foto del horario',
                  onPressed: _isWorkingPhoto ? null : _pickPhotoSource,
                  icon: _isWorkingPhoto
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.photo_camera_rounded),
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendTypedText(),
                    decoration: const InputDecoration(
                      hintText: 'Escríbeme o dicta con el micrófono…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _MicButton(
                  isListening: _isListening,
                  onPressed: _toggleMic,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TurnBubble extends StatelessWidget {
  final _Turn turn;
  const _TurnBubble({required this.turn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Align(
      alignment: turn.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: turn.isUser
              ? theme.colorScheme.primary
              : (isDark
                    ? theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      )
                    : theme.colorScheme.surfaceContainerHighest),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (turn.source.isNotEmpty)
              Text(
                turn.source == 'foto'
                    ? 'Foto de tu horario'
                    : turn.source == 'voz'
                    ? 'Por voz'
                    : 'Por texto',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: turn.isUser
                      ? Colors.white.withValues(alpha: 0.8)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            Text(
              turn.text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: turn.isUser ? Colors.white : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final _Pending pending;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const _CandidateCard({
    required this.pending,
    required this.onSave,
    required this.onDiscard,
  });

  static const _dayNames = <int, String>{
    1: 'Lun',
    2: 'Mar',
    3: 'Mié',
    4: 'Jue',
    5: 'Vie',
    6: 'Sáb',
    7: 'Dom',
  };

  String _subtitle() {
    final candidate = pending.candidate;
    if (candidate.isTask) {
      final draft = candidate.taskDraft!;
      final when = DateFormat(
        'EEE d MMM · HH:mm',
        'es',
      ).format(draft.dueDate);
      final inferred = draft.dueDateWasInferred ? ' (a confirmar)' : '';
      final project = draft.matchedProjectName ?? draft.projectHint;
      return '$when$inferred${project == null ? '' : ' · $project'}';
    }
    final draft = candidate.scheduleDraft!;
    final days = draft.weekDays.map((d) => _dayNames[d] ?? '').join(', ');
    final hours =
        '${DateFormat('HH:mm').format(draft.firstStart)} – ${DateFormat('HH:mm').format(draft.firstEnd)}';
    final repeat = draft.isSingleEvent ? 'Solo una vez' : 'Fijo cada semana';
    final place = draft.location.isEmpty ? '' : ' · ${draft.location}';
    return '$days · $hours · $repeat$place';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final candidate = pending.candidate;
    final isTask = candidate.isTask;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTask
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : DesignTokens.mintStrong.withValues(alpha: 0.45),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isTask
                      ? theme.colorScheme.primary.withValues(alpha: 0.14)
                      : DesignTokens.mint.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isTask
                      ? Icons.add_task_rounded
                      : Icons.school_rounded,
                  size: 20,
                  color: isTask
                      ? (isDark
                            ? DesignTokens.lilac
                            : theme.colorScheme.primary)
                      : DesignTokens.mintStrong,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isTask
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : DesignTokens.mint.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isTask ? 'TAREA' : 'CLASE · HORARIO',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isTask
                          ? (isDark
                                ? DesignTokens.lilac
                                : theme.colorScheme.primary)
                          : DesignTokens.mintStrong,
                    ),
                  ),
                ),
              ),
              if (!pending.saved)
                IconButton(
                  tooltip: 'Descartar',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDiscard,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(candidate.title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(_subtitle(), style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          if (pending.saved)
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: DesignTokens.mintStrong,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isTask
                        ? 'Guardada en tus tareas.'
                        : 'Fijada en tu horario. Puedes editarla en Calendario.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: UniPrimaryButton(
                    label: isTask ? 'Guardar tarea' : 'Fijar en horario',
                    icon: Icons.check_rounded,
                    onPressed: candidate.canSave ? onSave : null,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;

  const _MicButton({required this.isListening, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isListening
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
          shape: BoxShape.circle,
          border: Border(
            bottom: BorderSide(
              color: isListening
                  ? theme.colorScheme.error.withValues(alpha: 0.55)
                  : DesignTokens.accentDeep,
              width: 4,
            ),
          ),
        ),
        child: Icon(
          isListening ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

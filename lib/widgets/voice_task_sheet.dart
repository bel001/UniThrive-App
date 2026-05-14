import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/design_tokens.dart';
import '../models/project.dart';
import '../models/voice_task_draft.dart';
import '../services/voice_ai_parse_service.dart';
import '../services/voice_task_capture_service.dart';
import '../services/voice_task_parser.dart';
import '../state/app_state.dart';
import 'uni_card.dart';
import 'uni_primary_button.dart';

class VoiceTaskSheet extends StatefulWidget {
  final VoiceAiParseService aiParseService;
  final VoiceTaskCaptureService captureService;
  final VoiceTaskParser parser;

  VoiceTaskSheet({
    super.key,
    VoiceAiParseService? aiParseService,
    VoiceTaskCaptureService? captureService,
    VoiceTaskParser? parser,
  }) : aiParseService = aiParseService ?? VoiceAiParseService.instance,
       captureService = captureService ?? VoiceTaskCaptureService.instance,
       parser = parser ?? const VoiceTaskParser();

  @override
  State<VoiceTaskSheet> createState() => _VoiceTaskSheetState();
}

class _VoiceTaskSheetState extends State<VoiceTaskSheet> {
  static const _quickTasksValue = '__quick_tasks__';
  static const _createProjectValue = '__create_voice_project__';

  late final TextEditingController _titleController;
  late VoiceTaskDraft _draft;

  String _selectedProjectValue = _quickTasksValue;
  String _statusText =
      'Toca el micrófono y dicta algo como “Tarea de Cálculo: resolver guía 4 para el jueves a las 6 pm”.';
  String? _captureError;
  bool _isListening = false;
  bool _isSaving = false;
  bool _isEnhancingWithAi = false;
  double _soundLevel = 0;
  bool _projectSelectionLocked = false;
  String? _aiStatusText;
  String? _lastAiTranscript;

  @override
  void initState() {
    super.initState();
    _draft = VoiceTaskDraft.empty();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    widget.captureService.stopListening();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppStateProvider.of(context);
    final activeProjects = appState.activeProjects;
    final matchedProject = _findMatchedProject(activeProjects);
    final canCreateProject =
        matchedProject == null &&
        (_draft.projectHint?.trim().isNotEmpty ?? false);
    final aiEnabled =
        appState.voiceAiEnabled && appState.voiceAiEndpointUrl.isNotEmpty;

    if (!_projectSelectionLocked) {
      _selectedProjectValue = _initialProjectValue(
        matchedProject: matchedProject,
        canCreateProject: canCreateProject,
      );
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final level = (_soundLevel.abs() / 50).clamp(0.0, 1.0);

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
            mainAxisSize: MainAxisSize.min,
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
                          'Nueva tarea por voz',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Dicta la tarea, el curso y la fecha. Antes de guardar puedes corregir cualquier campo.',
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
                        final statusChip = _StatusChip(
                          label: _isListening ? 'Escuchando' : 'Vista previa',
                          icon: _isListening
                              ? Icons.graphic_eq
                              : Icons.auto_awesome,
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
                              statusChip,
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
                            statusChip,
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
                            : 'Todavía no hay audio procesado. Habla con una frase natural y corta para que el parser tenga una base más clara.',
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
                      _VoiceAssistBanner(
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
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Tarea',
                  hintText: 'Ej. Resolver guía 4',
                  prefixIcon: Icon(Icons.task_alt_rounded),
                ),
                onChanged: (value) {
                  _draft = _draft.copyWith(title: value);
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedProjectValue,
                isExpanded: true,
                items: _buildProjectItems(
                  activeProjects: activeProjects,
                  canCreateProject: canCreateProject,
                ),
                selectedItemBuilder: (context) =>
                    _buildProjectLabels(
                      activeProjects: activeProjects,
                      canCreateProject: canCreateProject,
                    ).map((label) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                decoration: const InputDecoration(
                  labelText: 'Curso o proyecto',
                  prefixIcon: Icon(Icons.school_rounded),
                ),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedProjectValue = value;
                          _projectSelectionLocked = true;
                        });
                      },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stack = constraints.maxWidth < 360;
                  final dateButton = OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(
                      DateFormat('EEE d MMM', 'es').format(_draft.dueDate),
                    ),
                  );
                  final timeButton = OutlinedButton.icon(
                    onPressed: _isSaving ? null : _pickTime,
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: Text(
                      DateFormat('hh:mm a', 'es').format(_draft.dueDate),
                    ),
                  );

                  if (stack) {
                    return Column(
                      children: [
                        SizedBox(width: double.infinity, child: dateButton),
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: timeButton),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: dateButton),
                      const SizedBox(width: 12),
                      Expanded(child: timeButton),
                    ],
                  );
                },
              ),
              if (_draft.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._draft.notes.map(
                  (note) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _InlineNote(note: note),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stack = constraints.maxWidth < 360;
                  final saveButton = IgnorePointer(
                    ignoring: !_canSave,
                    child: Opacity(
                      opacity: _canSave ? 1 : 0.55,
                      child: UniPrimaryButton(
                        label: _isSaving ? 'Guardando...' : 'Guardar tarea',
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: () => _saveTask(appState),
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

  bool get _canSave => !_isSaving && _titleController.text.trim().isNotEmpty;

  Project? _findMatchedProject(List<Project> activeProjects) {
    final matchedName = _draft.matchedProjectName;
    if (matchedName == null) {
      return null;
    }

    for (final project in activeProjects) {
      if (project.name == matchedName) {
        return project;
      }
    }
    return null;
  }

  String _initialProjectValue({
    required Project? matchedProject,
    required bool canCreateProject,
  }) {
    if (_projectSelectionLocked) {
      return _selectedProjectValue;
    }
    if (matchedProject != null) {
      return matchedProject.id;
    }
    if (canCreateProject) {
      return _createProjectValue;
    }
    return _quickTasksValue;
  }

  List<DropdownMenuItem<String>> _buildProjectItems({
    required List<Project> activeProjects,
    required bool canCreateProject,
  }) {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: _quickTasksValue,
        child: Text('Tareas rápidas'),
      ),
    ];

    if (canCreateProject) {
      items.add(
        DropdownMenuItem<String>(
          value: _createProjectValue,
          child: Text('Crear curso "${_draft.projectHint}"'),
        ),
      );
    }

    for (final project in activeProjects) {
      items.add(
        DropdownMenuItem<String>(
          value: project.id,
          child: Text(
            project.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return items;
  }

  List<String> _buildProjectLabels({
    required List<Project> activeProjects,
    required bool canCreateProject,
  }) {
    return [
      'Tareas rápidas',
      if (canCreateProject) 'Crear curso "${_draft.projectHint}"',
      ...activeProjects.map((project) => project.name),
    ];
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await widget.captureService.stopListening();
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _statusText = _draft.hasTranscript
            ? 'Dictado detenido. Ajusta la vista previa y guarda.'
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
          projects: appState.activeProjects,
        );
        setState(() {
          _draft = parsed;
          _titleController.value = TextEditingValue(
            text: parsed.title,
            selection: TextSelection.collapsed(offset: parsed.title.length),
          );
          _captureError = null;
          _statusText = isFinal
              ? aiEnabled
                    ? 'Dictado listo. Intentando afinarlo con IA segura.'
                    : 'Dictado listo. Revisa la vista previa antes de guardar.'
              : 'Estoy escuchando y preparando la tarea...';
          _projectSelectionLocked = false;
        });
        if (isFinal) {
          _enhanceTaskWithAi(
            appState: appState,
            transcript: transcript,
            activeProjects: appState.activeProjects,
          );
        }
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() {
          _soundLevel = level;
        });
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
      _statusText = 'Escuchando tu tarea...';
      _captureError = null;
    });
  }

  Future<void> _enhanceTaskWithAi({
    required AppState appState,
    required String transcript,
    required List<Project> activeProjects,
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
      _aiStatusText = 'Afinando la tarea con tu endpoint IA seguro...';
    });

    final outcome = await widget.aiParseService.enhanceTask(
      transcript: normalizedTranscript,
      referenceTime: DateTime.now(),
      activeProjects: activeProjects,
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
      _projectSelectionLocked = false;
      _isEnhancingWithAi = false;
      _aiStatusText =
          'La tarea se refinó con IA y quedó lista para revisar antes de guardar.';
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _draft.dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('es'),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _draft = _draft.copyWith(
        dueDate: DateTime(
          selected.year,
          selected.month,
          selected.day,
          _draft.dueDate.hour,
          _draft.dueDate.minute,
        ),
        dueDateWasInferred: false,
      );
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_draft.dueDate),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _draft = _draft.copyWith(
        dueDate: DateTime(
          _draft.dueDate.year,
          _draft.dueDate.month,
          _draft.dueDate.day,
          selected.hour,
          selected.minute,
        ),
        dueTimeWasInferred: false,
      );
    });
  }

  Future<void> _saveTask(AppState appState) async {
    final trimmedTitle = _titleController.text.trim();
    if (trimmedTitle.isEmpty || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _captureError = null;
    });

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    Project targetProject;
    if (_selectedProjectValue == _quickTasksValue) {
      targetProject = appState.getOrCreateQuickTasksProject();
    } else if (_selectedProjectValue == _createProjectValue &&
        (_draft.projectHint?.trim().isNotEmpty ?? false)) {
      targetProject = appState.addProject(
        name: _draft.projectHint!.trim(),
        dueDate: _draft.dueDate.add(const Duration(days: 120)),
        color: DesignTokens.accent,
        description: 'Curso creado desde dictado de voz.',
        tag: 'Curso',
      );
    } else {
      targetProject =
          appState.projectById(_selectedProjectValue) ??
          appState.getOrCreateQuickTasksProject();
    }

    appState.addTask(
      projectId: targetProject.id,
      title: trimmedTitle,
      dueDate: _draft.dueDate,
      description: _draft.transcript.isEmpty
          ? null
          : 'Dictado: ${_draft.transcript}',
    );

    await widget.captureService.stopListening();

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Text(
          'Tarea "$trimmedTitle" guardada en ${targetProject.name} para ${DateFormat('EEE d MMM · hh:mm a', 'es').format(_draft.dueDate)}.',
        ),
        action: SnackBarAction(label: 'Cerrar', onPressed: () {}),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color tone;
  final Color foregroundColor;

  const _StatusChip({
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

class _InlineNote extends StatelessWidget {
  final String note;

  const _InlineNote({required this.note});

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

class _VoiceAssistBanner extends StatelessWidget {
  const _VoiceAssistBanner({required this.icon, required this.text});

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

Future<void> showVoiceTaskSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => VoiceTaskSheet(),
  );
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/alarm_schedule.dart';
import '../../state/app_state.dart';

class AlarmScreen extends StatelessWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarmas'),
        actions: [
          IconButton(
            tooltip: 'Abrir reloj del sistema',
            onPressed: () => appState.openSystemAlarmClock(),
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAlarmSheet(context),
        icon: const Icon(Icons.alarm_add_rounded),
        label: const Text('Nueva alarma'),
      ),
      body: AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          final alarms = [...appState.alarmSchedules]
            ..sort((a, b) {
              final aNext = a.nextOccurrence() ?? DateTime(2100);
              final bNext = b.nextOccurrence() ?? DateTime(2100);
              return aNext.compareTo(bNext);
            });
          if (alarms.isEmpty) {
            return _AlarmEmptyState(onCreate: () => showAlarmSheet(context));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
            itemCount: alarms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final alarm = alarms[index];
              return _AlarmCard(
                alarm: alarm,
                onToggle: (value) => appState.toggleAlarm(alarm.id, value),
                onEdit: () => showAlarmSheet(context, alarm: alarm),
                onDelete: () => appState.deleteAlarm(alarm.id),
                onDuplicate: () async {
                  await appState.createAlarm(
                    title: '${alarm.title} copia',
                    time: TimeOfDay(hour: alarm.hour, minute: alarm.minute),
                    repeatType: alarm.repeatType,
                    weekDays: alarm.weekDays,
                    startDate: alarm.startDate,
                    endDate: alarm.endDate,
                    snoozeMinutes: alarm.snoozeMinutes,
                    maxSnoozes: alarm.maxSnoozes,
                    vibrate: alarm.vibrate,
                    soundAssetPath: alarm.soundAssetPath,
                  );
                },
                onSkipNext: () => appState.skipNextAlarmOccurrence(alarm.id),
                onPause: () async {
                  final until = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (until != null) {
                    await appState.pauseAlarmUntil(
                      alarm.id,
                      DateTime(until.year, until.month, until.day, 23, 59),
                    );
                  }
                },
                onOpenSystem: () =>
                    appState.openSystemAlarmClock(alarmId: alarm.id),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> showAlarmSheet(BuildContext context, {AlarmSchedule? alarm}) {
  final appState = AppStateProvider.of(context);
  final isEditing = alarm != null;
  final titleController = TextEditingController(text: alarm?.title ?? '');
  var time = alarm == null
      ? TimeOfDay.now()
      : TimeOfDay(hour: alarm.hour, minute: alarm.minute);
  var repeatType = alarm?.repeatType ?? AlarmRepeatType.once;
  final selectedWeekDays = <int>{
    ...(alarm?.weekDays.isNotEmpty == true
        ? alarm!.weekDays
        : [DateTime.now().weekday]),
  };
  DateTime? startDate = alarm?.startDate;
  DateTime? endDate = alarm?.endDate;
  var snoozeMinutes = alarm?.snoozeMinutes ?? 10;
  var maxSnoozes = alarm?.maxSnoozes ?? 3;
  var vibrate = alarm?.vibrate ?? true;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickDate({
            required DateTime? initialDate,
            required ValueChanged<DateTime?> onPicked,
          }) async {
            final picked = await showDatePicker(
              context: context,
              initialDate: initialDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            onPicked(picked);
          }

          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      20,
                      24,
                      MediaQuery.of(context).viewInsets.bottom + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEditing ? 'Editar alarma' : 'Nueva alarma',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.of(sheetContext).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.alarm_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_rounded),
                    title: const Text('Hora'),
                    subtitle: Text(time.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (picked != null) {
                        setState(() => time = picked);
                      }
                    },
                  ),
                  DropdownButtonFormField<AlarmRepeatType>(
                    initialValue: repeatType,
                    decoration: const InputDecoration(
                      labelText: 'Repetición',
                      prefixIcon: Icon(Icons.repeat_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: AlarmRepeatType.once,
                        child: Text('Una vez'),
                      ),
                      DropdownMenuItem(
                        value: AlarmRepeatType.daily,
                        child: Text('Todos los días'),
                      ),
                      DropdownMenuItem(
                        value: AlarmRepeatType.weekly,
                        child: Text('Días de semana'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => repeatType = value ?? AlarmRepeatType.once,
                    ),
                  ),
                  if (repeatType == AlarmRepeatType.weekly) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (index) {
                        const labels = ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'];
                        final weekday = index + 1;
                        final selected = selectedWeekDays.contains(weekday);
                        return ChoiceChip(
                          label: Text(labels[index]),
                          selected: selected,
                          onSelected: (_) => setState(() {
                            if (selected && selectedWeekDays.length > 1) {
                              selectedWeekDays.remove(weekday);
                            } else {
                              selectedWeekDays.add(weekday);
                            }
                          }),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _DateRangeRow(
                    startDate: startDate,
                    endDate: endDate,
                    onPickStart: () => pickDate(
                      initialDate: startDate,
                      onPicked: (date) => setState(() => startDate = date),
                    ),
                    onPickEnd: () => pickDate(
                      initialDate: endDate,
                      onPicked: (date) => setState(() => endDate = date),
                    ),
                    onClearEnd: () => setState(() => endDate = null),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: vibrate,
                    title: const Text('Vibración'),
                    onChanged: (value) => setState(() => vibrate = value),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: snoozeMinutes,
                          decoration: const InputDecoration(
                            labelText: 'Posponer',
                          ),
                          items: const [5, 10, 15, 20, 30]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('$value min'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setState(
                            () => snoozeMinutes = value ?? snoozeMinutes,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: maxSnoozes,
                          decoration: const InputDecoration(labelText: 'Máx.'),
                          items: const [0, 1, 2, 3, 5]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('$value veces'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => maxSnoozes = value ?? maxSnoozes),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final title = titleController.text.trim().isEmpty
                                ? 'Alarma'
                                : titleController.text.trim();
                            if (alarm == null) {
                              await appState.createAlarm(
                                title: title,
                                time: time,
                                repeatType: repeatType,
                                weekDays: selectedWeekDays.toList()..sort(),
                                startDate: startDate,
                                endDate: endDate,
                                snoozeMinutes: snoozeMinutes,
                                maxSnoozes: maxSnoozes,
                                vibrate: vibrate,
                              );
                            } else {
                              await appState.updateAlarm(
                                alarm.copyWith(
                                  title: title,
                                  hour: time.hour,
                                  minute: time.minute,
                                  repeatType: repeatType,
                                  weekDays: selectedWeekDays.toList()..sort(),
                                  startDate: () => startDate,
                                  endDate: () => endDate,
                                  snoozeMinutes: snoozeMinutes,
                                  maxSnoozes: maxSnoozes,
                                  vibrate: vibrate,
                                ),
                              );
                            }
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                          child: const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
        },
      );
    },
  );
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({
    required this.alarm,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onSkipNext,
    required this.onPause,
    required this.onOpenSystem,
  });

  final AlarmSchedule alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onSkipNext;
  final VoidCallback onPause;
  final VoidCallback onOpenSystem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = alarm.nextOccurrence();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    alarm.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Switch.adaptive(value: alarm.enabled, onChanged: onToggle),
              ],
            ),
            Text(alarm.timeLabel, style: theme.textTheme.displayMedium),
            const SizedBox(height: 4),
            Text(
              next == null
                  ? 'Sin próxima ocurrencia'
                  : 'Próxima: ${DateFormat('EEE d MMM, HH:mm', 'es').format(next)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(alarm.repeatLabel)),
                if (alarm.pausedUntil != null)
                  Chip(
                    avatar: const Icon(Icons.pause_rounded, size: 16),
                    label: Text(
                      'Pausada hasta ${DateFormat('d/M').format(alarm.pausedUntil!)}',
                    ),
                  ),
                if (alarm.vibrate)
                  const Chip(
                    avatar: Icon(Icons.vibration_rounded, size: 16),
                    label: Text('Vibra'),
                  ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: onSkipNext,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Omitir'),
                ),
                TextButton.icon(
                  onPressed: onPause,
                  icon: const Icon(Icons.pause_circle_outline),
                  label: const Text('Pausar'),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'duplicate':
                        onDuplicate();
                        break;
                      case 'system':
                        onOpenSystem();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'duplicate', child: Text('Duplicar')),
                    PopupMenuItem(
                      value: 'system',
                      child: Text('Abrir reloj del sistema'),
                    ),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  const _DateRangeRow({
    required this.startDate,
    required this.endDate,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClearEnd,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onClearEnd;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('d MMM', 'es');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.today_rounded, size: 18),
          label: Text(
            startDate == null
                ? 'Desde hoy'
                : 'Desde ${formatter.format(startDate!)}',
          ),
          onPressed: onPickStart,
        ),
        ActionChip(
          avatar: const Icon(Icons.event_busy_rounded, size: 18),
          label: Text(
            endDate == null ? 'Sin fin' : 'Hasta ${formatter.format(endDate!)}',
          ),
          onPressed: onPickEnd,
        ),
        if (endDate != null)
          IconButton(
            tooltip: 'Quitar fecha fin',
            onPressed: onClearEnd,
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    );
  }
}

class _AlarmEmptyState extends StatelessWidget {
  const _AlarmEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 360;
        return SingleChildScrollView(
          padding: EdgeInsets.all(compact ? 20 : 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.alarm_add_rounded,
                    size: compact ? 48 : 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: compact ? 10 : 16),
                  Text(
                    'Sin alarmas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea despertadores para clases, estudio o rutinas.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: compact ? 12 : 20),
                  FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Crear alarma'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

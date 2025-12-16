import 'package:flutter/material.dart';

import '../../models/schedule.dart';
import '../../services/calendar_sync_service.dart';
import '../../state/app_state.dart';
import '../../widgets/uni_primary_button.dart';

const _calendarAccent = Color(0xFF9FCFBB); // verde menta para botones activos
const _calendarAccentDark = Color(0xFF7FB5A0); // variante en modo oscuro
const _chipBgLight = Color(0xFFF0FFF8); // fondo inactivo claro
const _chipBgDark = Color(0xFF1A2E27); // fondo inactivo oscuro

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _hideWeekends = false;
  bool _monthlyView = false;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final blocks = appState.blocksForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Horario Semanal'),
        actions: [
          TextButton(
            onPressed: () => _promptOrganize(appState),
            child: const Text('Organízate'),
          ),
          IconButton(
            tooltip: 'Sincronizar',
            onPressed: () => _openCalendarSync(context, appState),
            icon: const Icon(Icons.sync_alt_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ocultar fin de semana'),
                Switch(
                  value: _hideWeekends,
                  onChanged: (value) => setState(() => _hideWeekends = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _viewModeChip(
                  label: 'Semana',
                  selected: !_monthlyView,
                  onPressed: () => setState(() => _monthlyView = false),
                ),
                _viewModeChip(
                  label: 'Mes',
                  selected: _monthlyView,
                  onPressed: () => setState(() => _monthlyView = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_monthlyView)
            Expanded(child: _buildMonthGrid(appState.scheduleBlocks))
          else ...[
            _buildDaySelector(),
            const SizedBox(height: 12),
            Expanded(child: _buildScheduleList(blocks)),
          ],
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 130), // Avoid bottom nav bar
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add),
          onPressed: () => _showClassSheet(appState: appState),
        ),
      ),
    );
  }

  ChoiceChip _viewModeChip({
    required String label,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = isDark ? _calendarAccentDark : _calendarAccent;
    final inactiveBg = isDark ? _chipBgDark : _chipBgLight;
    final inactiveText = isDark ? Colors.white70 : const Color(0xFF4B5563);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onPressed(),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : inactiveText,
      ),
      backgroundColor: inactiveBg,
      selectedColor: activeColor,
      side: BorderSide(
        color: selected
            ? Colors.transparent
            : inactiveText.withValues(alpha: 0.35),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDaySelector() {
    final weekDays = ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = isDark ? _calendarAccentDark : _calendarAccent;
    final unselectedBg = isDark ? const Color(0xFF241A37) : _chipBgLight;
    final unselectedBorder = isDark
        ? const Color(0xFF3A2C52)
        : const Color(0xFFE2E8F0);
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          final weekday = index + 1;
          if (_hideWeekends &&
              (weekday == DateTime.saturday || weekday == DateTime.sunday)) {
            return const SizedBox.shrink();
          }
          final day = _selectedDay.add(
            Duration(days: weekday - _selectedDay.weekday),
          );
          final isSelected = _isSameDay(day, _selectedDay);
          return GestureDetector(
            onTap: () => setState(() {
              _selectedDay = day;
              _focusedMonth = DateTime(day.year, day.month);
            }),
            child: Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : unselectedBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? Colors.transparent : unselectedBorder,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: selectedColor.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekDays[index],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScheduleList(List<ScheduleBlock> blocks) {
    final appState = AppStateProvider.of(context);
    if (blocks.isEmpty) {
      return Center(
        child: Text(
          'No hay clases programadas para este día.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    final normalized = _uniqueBlocks(blocks)
      ..sort((a, b) => a.start.compareTo(b.start));
    final conflictColors = _conflictHighlights(normalized);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: normalized.length,
      itemBuilder: (context, index) {
        final block = normalized[index];
        final allowDurationEdit = _canStretchDuration(block);
        return _ScheduleCard(
          block: block,
          onEdit: () => _showClassSheet(appState: appState, block: block),
          onDelete: () => appState.removeScheduleBlock(block.id),
          onReschedule: () => _rescheduleBlock(block),
          onAdjustDuration: allowDurationEdit
              ? () => _adjustBlockDuration(block)
              : null,
          conflictColor: conflictColors[block.id],
        );
      },
    );
  }

  Widget _buildMonthGrid(List<ScheduleBlock> allBlocks) {
    final theme = Theme.of(context);
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final startOffset = (firstDay.weekday % 7);
    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;
    final blocksByDay = <int, List<ScheduleBlock>>{};
    for (final block in allBlocks) {
      if (block.start.year == _focusedMonth.year &&
          block.start.month == _focusedMonth.month) {
        blocksByDay.putIfAbsent(block.start.day, () => []).add(block);
      }
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(
                  () => _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                  ),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                _monthTitle(_focusedMonth),
                style: theme.textTheme.titleMedium,
              ),
              IconButton(
                onPressed: () => setState(
                  () => _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                  ),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              final dayNumber = index - startOffset + 1;
              if (index < startOffset || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final dayDate = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                dayNumber,
              );
              final events = blocksByDay[dayNumber] ?? [];
              final isSelected = _isSameDay(dayDate, _selectedDay);
              return GestureDetector(
                onTap: () => _showDayDetail(context, dayDate, events),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$dayNumber',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _buildEventDots(events),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventDots(List<ScheduleBlock> events) {
    if (events.isEmpty) return const SizedBox(height: 8);
    return Row(
      children: events.take(3).map((event) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(color: event.color, shape: BoxShape.circle),
        );
      }).toList(),
    );
  }

  List<ScheduleBlock> _uniqueBlocks(List<ScheduleBlock> blocks) {
    final seen = <String>{};
    final result = <ScheduleBlock>[];
    for (final block in blocks) {
      final key = block.linkedTaskId != null
          ? '${block.linkedTaskId}_${block.start.toIso8601String()}'
          : block.id;
      if (seen.add(key)) result.add(block);
    }
    return result;
  }

  bool _canStretchDuration(ScheduleBlock block) =>
      block.category == ScheduleCategory.project ||
      block.category == ScheduleCategory.task;

  Future<void> _adjustBlockDuration(ScheduleBlock block) async {
    final appState = AppStateProvider.of(context);
    double minutes = block.end
        .difference(block.start)
        .inMinutes
        .clamp(15, 180)
        .toDouble();
    final selected = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Text(
                      'Duración de la sesión',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${minutes.round()} minutos',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Slider(
                      min: 15,
                      max: 180,
                      divisions: 33,
                      value: minutes,
                      label: '${minutes.round()} min',
                      onChanged: (value) => setState(() => minutes = value),
                    ),
                    const SizedBox(height: 12),
                    UniPrimaryButton(
                      label: 'Actualizar duración',
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(minutes.round()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    final newEnd = block.start.add(Duration(minutes: selected));
    appState.updateScheduleBlock(block.id, end: newEnd);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duración ajustada a $selected min.')),
    );
  }

  Map<String, Color> _conflictHighlights(List<ScheduleBlock> blocks) {
    const palette = [
      Color(0xFFFFA8A8),
      Color(0xFF7DD3FC),
      Color(0xFFFFE29D),
      Color(0xFFB4F0D2),
      Color(0xFFD1C4E9),
    ];
    final conflicts = <String, Color>{};
    bool overlaps(ScheduleBlock a, ScheduleBlock b) =>
        a.start.isBefore(b.end) && b.start.isBefore(a.end);
    var paletteIndex = 0;
    for (var i = 0; i < blocks.length; i++) {
      for (var j = i + 1; j < blocks.length; j++) {
        if (overlaps(blocks[i], blocks[j])) {
          conflicts.putIfAbsent(
            blocks[i].id,
            () => palette[paletteIndex % palette.length],
          );
          conflicts.putIfAbsent(
            blocks[j].id,
            () => palette[(paletteIndex + 1) % palette.length],
          );
          paletteIndex++;
        }
      }
    }
    return conflicts;
  }

  Future<void> _showDayDetail(
    BuildContext context,
    DateTime day,
    List<ScheduleBlock> events,
  ) async {
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sin eventos para este día.')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Text(
                'Agenda del ${day.day}/${day.month}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              ...events.map(
                (event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: event.color,
                    child: Text(
                      event.start.hour.toString().padLeft(2, '0'),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  title: Text(event.title),
                  subtitle: Text(
                    '${_timeWindowLabel(event)} · ${event.location}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _selectedDay = day;
                    _monthlyView = false;
                  });
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Ver día completo'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _monthTitle(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _timeWindowLabel(ScheduleBlock block) {
    final localizations = MaterialLocalizations.of(context);
    final startLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(block.start),
      alwaysUse24HourFormat: true,
    );
    final endLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(block.end),
      alwaysUse24HourFormat: true,
    );
    return '$startLabel - $endLabel';
  }

  Future<void> _promptOrganize(AppState appState) async {
    final scope = await showModalBottomSheet<_OrganizeScope>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_view_day_outlined),
                title: const Text('Planear solo este día'),
                subtitle: Text(
                  'Ubicamos tareas pendientes en ${_selectedDay.day}/${_selectedDay.month}.',
                ),
                onTap: () => Navigator.of(sheetContext).pop(_OrganizeScope.day),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Planear todo el mes'),
                subtitle: Text(
                  'Repartimos los checklists de ${_monthTitle(_focusedMonth)}.',
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_OrganizeScope.month),
              ),
            ],
          ),
        );
      },
    );
    if (scope == null || !mounted) return;
    if (scope == _OrganizeScope.day) {
      final planned = await appState.autoPlanDay(_selectedDay);
      final message = planned
          ? 'Listo, añadí bloques de estudio para tus tareas pendientes.'
          : 'Ese día ya está organizado o no hay tareas urgentes.';
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } else {
      final plannedDays = await appState.autoPlanMonth(_focusedMonth);
      final message = plannedDays > 0
          ? 'Organicé $plannedDays día(s) del mes con tus tareas.'
          : 'Tu mes ya tenía todo asignado o no hay pasos pendientes.';
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _openCalendarSync(BuildContext context, AppState appState) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.today_outlined),
                title: const Text('Exportar día en .ics'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await CalendarSyncService.exportBlocks(
                    context: context,
                    blocks: appState.blocksForDay(_selectedDay),
                    fileName: 'unithrive-dia.ics',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_view_week),
                title: const Text('Exportar semana completa'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final startOfWeek = _selectedDay.subtract(
                    Duration(days: _selectedDay.weekday - 1),
                  );
                  final weekBlocks = appState.scheduleBlocks
                      .where(
                        (block) =>
                            block.start.isAfter(
                              startOfWeek.subtract(const Duration(seconds: 1)),
                            ) &&
                            block.start.isBefore(
                              startOfWeek.add(const Duration(days: 7)),
                            ),
                      )
                      .toList();
                  await CalendarSyncService.exportBlocks(
                    context: context,
                    blocks: weekBlocks,
                    fileName: 'unithrive-semana.ics',
                    description: 'Tu horario semanal listo para importar.',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Importar desde .ics'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _promptImportIcs(context, appState);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _promptImportIcs(BuildContext context, AppState appState) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pegar contenido .ics'),
          content: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Pega aquí el contenido del archivo .ics',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Importar'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final imported = await CalendarSyncService.importIcs(
        controller.text,
        appState,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imported == 0
                ? 'No se detectaron eventos.'
                : 'Importados $imported eventos.',
          ),
        ),
      );
    }
  }

  Future<void> _showClassSheet({
    required AppState appState,
    ScheduleBlock? block,
  }) async {
    final editingBlock = block;
    final isEditing = editingBlock != null;
    final nameController = TextEditingController(
      text: editingBlock?.title ?? '',
    );
    final locationController = TextEditingController(
      text: editingBlock?.location ?? 'Edificio B, Aula 101',
    );
    TimeOfDay startTime = editingBlock != null
        ? TimeOfDay.fromDateTime(editingBlock.start)
        : const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = editingBlock != null
        ? TimeOfDay.fromDateTime(editingBlock.end)
        : const TimeOfDay(hour: 11, minute: 0);
    final Set<int> selectedDays = editingBlock == null
        ? {_selectedDay.weekday}
        : {editingBlock.start.weekday};
    int selectedDay = editingBlock?.start.weekday ?? _selectedDay.weekday;
    ScheduleCategory sheetCategory =
        editingBlock?.category ?? ScheduleCategory.classSession;

    // Recurrence state
    RecurrenceType selectedRecurrence =
        editingBlock?.recurrence ?? RecurrenceType.none;
    DateTime? recurrenceEndDate = editingBlock?.recurrenceEndDate;
    int recurrenceInterval = editingBlock?.recurrenceInterval ?? 1;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F0C1F)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final isDarkSheet = theme.brightness == Brightness.dark;
        final fieldFill = isDarkSheet ? const Color(0xFF1E1B35) : Colors.white;
        final borderColor = isDarkSheet
            ? const Color(0xFF3C3355)
            : const Color(0xFFE2E8F0);
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Editar clase' : 'Agregar clase',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _LabeledField(
                      label: 'Nombre de la clase',
                      controller: nameController,
                      hint: 'Ej. Álgebra Lineal',
                      fillColor: fieldFill,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'Profesor / Lugar',
                      controller: locationController,
                      hint: 'Ej. Dr. Alan Turing',
                      fillColor: fieldFill,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ScheduleCategory>(
                          value: sheetCategory,
                          isExpanded: true,
                          onChanged: (value) => setSheetState(() {
                            sheetCategory = value ?? sheetCategory;
                          }),
                          items: const [
                            DropdownMenuItem(
                              value: ScheduleCategory.classSession,
                              child: Text('Clase'),
                            ),
                            DropdownMenuItem(
                              value: ScheduleCategory.task,
                              child: Text('Tarea'),
                            ),
                            DropdownMenuItem(
                              value: ScheduleCategory.project,
                              child: Text('Proyecto / Enfoque'),
                            ),
                            DropdownMenuItem(
                              value: ScheduleCategory.event,
                              child: Text('Evento'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(isEditing ? 'Día' : 'Días'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: List.generate(7, (index) {
                        const labels = ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'];
                        final weekday = index + 1;
                        final active = isEditing
                            ? selectedDay == weekday
                            : selectedDays.contains(weekday);
                        return ChoiceChip(
                          selected: active,
                          label: Text(
                            labels[index],
                            style: TextStyle(
                              color: active
                                  ? Colors.white
                                  : (isDarkSheet
                                        ? Colors.white70
                                        : const Color(0xFF475569)),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selectedColor: isDarkSheet
                              ? _calendarAccentDark
                              : _calendarAccent,
                          backgroundColor: isDarkSheet
                              ? _chipBgDark
                              : _chipBgLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: active
                                  ? Colors.transparent
                                  : (isDarkSheet
                                        ? const Color(0xFF3C3355)
                                        : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          onSelected: (_) => setSheetState(() {
                            if (isEditing) {
                              selectedDay = weekday;
                            } else {
                              if (active) {
                                selectedDays.remove(weekday);
                              } else {
                                selectedDays.add(weekday);
                              }
                            }
                          }),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    // Recurrence selector
                    if (!isEditing)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.repeat,
                          color: isDarkSheet ? Colors.white70 : Colors.black87,
                        ),
                        title: const Text('Repetir'),
                        subtitle: Text(
                          selectedRecurrence == RecurrenceType.none
                              ? 'No se repite'
                              : _getRecurrenceLabel(
                                  selectedRecurrence,
                                  recurrenceInterval,
                                ),
                          style: TextStyle(
                            color: isDarkSheet
                                ? Colors.white60
                                : Colors.black54,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: isDarkSheet ? Colors.white38 : Colors.black38,
                        ),
                        onTap: () async {
                          final result = await _showRecurrenceOptions(
                            context,
                            selectedRecurrence,
                            recurrenceInterval,
                            isDarkSheet,
                          );
                          if (result != null) {
                            setSheetState(() {
                              selectedRecurrence =
                                  result['type'] as RecurrenceType;
                              recurrenceInterval = result['interval'] as int;
                              if (result.containsKey('endDate')) {
                                recurrenceEndDate =
                                    result['endDate'] as DateTime?;
                              }
                            });
                          }
                        },
                      ),
                    if (!isEditing) const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _TimePickerField(
                            label: 'Hora de inicio',
                            value: startTime,
                            fillColor: fieldFill,
                            borderColor: borderColor,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                              );
                              if (!context.mounted) return;
                              if (picked != null) {
                                setSheetState(() => startTime = picked);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimePickerField(
                            label: 'Hora de fin',
                            value: endTime,
                            fillColor: fieldFill,
                            borderColor: borderColor,
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                              );
                              if (!context.mounted) return;
                              if (picked != null) {
                                setSheetState(() => endTime = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: UniPrimaryButton(
                            label: 'Guardar',
                            onPressed: () {
                              final title = nameController.text.trim();
                              if (title.isEmpty) return;
                              final location =
                                  locationController.text.trim().isEmpty
                                  ? 'Edificio B, Aula 101'
                                  : locationController.text.trim();
                              if (editingBlock != null) {
                                final date = _dateForWeekday(
                                  selectedDay,
                                  reference: editingBlock.start,
                                );
                                final start = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  startTime.hour,
                                  startTime.minute,
                                );
                                final end = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  endTime.hour,
                                  endTime.minute,
                                );
                                appState.updateScheduleBlock(
                                  editingBlock.id,
                                  title: title,
                                  start: start,
                                  end: end,
                                  location: location,
                                  category: sheetCategory,
                                );
                              } else {
                                final days = selectedDays.isEmpty
                                    ? {_selectedDay.weekday}
                                    : selectedDays;
                                for (final weekday in days) {
                                  final date = _dateForWeekday(weekday);
                                  final start = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    startTime.hour,
                                    startTime.minute,
                                  );
                                  final end = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    endTime.hour,
                                    endTime.minute,
                                  );
                                  appState.addScheduleBlock(
                                    title: title,
                                    start: start,
                                    end: end,
                                    color: const Color(0xFF85D1F7),
                                    location: location,
                                    category: sheetCategory,
                                    recurrence: selectedRecurrence,
                                    recurrenceEndDate: recurrenceEndDate,
                                    recurrenceInterval: recurrenceInterval,
                                  );
                                }
                              }
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  DateTime _dateForWeekday(int weekday, {DateTime? reference}) {
    final base = reference ?? _selectedDay;
    return base.add(Duration(days: weekday - base.weekday));
  }

  Future<void> _rescheduleBlock(ScheduleBlock block) async {
    final appState = AppStateProvider.of(context);
    final duration = block.end.difference(block.start);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: block.start,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;
    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(block.start),
    );
    if (pickedTime == null) return;
    if (!mounted) return;
    final start = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final end = start.add(duration);
    appState.updateScheduleBlock(block.id, start: start, end: end);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Evento reprogramado.')));
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleBlock block;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReschedule;
  final Color? conflictColor;
  final VoidCallback? onAdjustDuration;
  const _ScheduleCard({
    required this.block,
    required this.onEdit,
    required this.onDelete,
    required this.onReschedule,
    this.conflictColor,
    this.onAdjustDuration,
  });

  @override
  Widget build(BuildContext context) {
    final time =
        '${block.start.hour.toString().padLeft(2, '0')}:${block.start.minute.toString().padLeft(2, '0')}';
    final end =
        '${block.end.hour.toString().padLeft(2, '0')}:${block.end.minute.toString().padLeft(2, '0')}';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = Color.alphaBlend(
      block.color.withValues(alpha: isDark ? 0.30 : 0.15),
      isDark ? const Color(0xFF161126) : Colors.white,
    );
    final hasConflict = conflictColor != null;
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: block.color.withValues(alpha: isDark ? 0.5 : 0.2),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasConflict)
                Container(
                  width: 6,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: conflictColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    end,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      block.location,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white70
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Chip(
                      label: Text(
                        _categoryLabel(block.category),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : block.color,
                        ),
                      ),
                      backgroundColor: block.color.withValues(alpha: 0.25),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.more_vert,
                  color: isDark ? Colors.white70 : theme.iconTheme.color,
                ),
                onPressed: () => _showBlockActions(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlockActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar clase'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onEdit();
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: const Text('Reprogramar'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onReschedule();
                },
              ),
              if (onAdjustDuration != null)
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text('Cambiar duración'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onAdjustDuration?.call();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _OrganizeScope { day, month }

String _categoryLabel(ScheduleCategory category) {
  switch (category) {
    case ScheduleCategory.task:
      return 'Tarea';
    case ScheduleCategory.project:
      return 'Proyecto';
    case ScheduleCategory.event:
      return 'Evento';
    default:
      return 'Clase';
  }
}

String _getRecurrenceLabel(RecurrenceType type, int interval) {
  switch (type) {
    case RecurrenceType.none:
      return 'No se repite';
    case RecurrenceType.daily:
      return interval == 1 ? 'Todos los días' : 'Cada $interval días';
    case RecurrenceType.weekly:
      return interval == 1 ? 'Todas las semanas' : 'Cada $interval semanas';
    case RecurrenceType.monthly:
      return interval == 1 ? 'Todos los meses' : 'Cada $interval meses';
    case RecurrenceType.yearly:
      return 'Todos los años';
    case RecurrenceType.custom:
      return 'Personalizado';
  }
}

Future<Map<String, dynamic>?> _showRecurrenceOptions(
  BuildContext context,
  RecurrenceType currentType,
  int currentInterval,
  bool isDark,
) async {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    backgroundColor: isDark ? const Color(0xFF0F0C1F) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      RecurrenceType selectedType = currentType;
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Repetir',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                _RecurrenceOption(
                  label: 'No se repite',
                  selected: selectedType == RecurrenceType.none,
                  onTap: () {
                    Navigator.pop(context, {
                      'type': RecurrenceType.none,
                      'interval': 1,
                    });
                  },
                ),
                _RecurrenceOption(
                  label: 'Todos los días',
                  selected: selectedType == RecurrenceType.daily,
                  onTap: () {
                    Navigator.pop(context, {
                      'type': RecurrenceType.daily,
                      'interval': 1,
                    });
                  },
                ),
                _RecurrenceOption(
                  label: 'Todas las semanas',
                  selected: selectedType == RecurrenceType.weekly,
                  onTap: () {
                    Navigator.pop(context, {
                      'type': RecurrenceType.weekly,
                      'interval': 1,
                    });
                  },
                ),
                _RecurrenceOption(
                  label: 'Todos los meses',
                  selected: selectedType == RecurrenceType.monthly,
                  onTap: () {
                    Navigator.pop(context, {
                      'type': RecurrenceType.monthly,
                      'interval': 1,
                    });
                  },
                ),
                _RecurrenceOption(
                  label: 'Todos los años',
                  selected: selectedType == RecurrenceType.yearly,
                  onTap: () {
                    Navigator.pop(context, {
                      'type': RecurrenceType.yearly,
                      'interval': 1,
                    });
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      );
    },
  );
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final Color? fillColor;
  final Color? borderColor;
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.fillColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedFill =
        fillColor ?? (isDark ? const Color(0xFF1E1B35) : Colors.white);
    final resolvedBorder =
        borderColor ??
        (isDark ? const Color(0xFF3C3355) : const Color(0xFFE2E8F0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: resolvedFill,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: resolvedBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;
  final Color? fillColor;
  final Color? borderColor;
  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.fillColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedFill =
        fillColor ?? (isDark ? const Color(0xFF1B1529) : Colors.white);
    final resolvedBorder =
        borderColor ??
        (isDark ? const Color(0xFF3C3355) : const Color(0xFFE2E8F0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              border: Border.all(color: resolvedBorder),
              borderRadius: BorderRadius.circular(18),
              color: resolvedFill,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value.format(context), style: theme.textTheme.bodyLarge),
                Icon(
                  Icons.access_time_outlined,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RecurrenceOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RecurrenceOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? _calendarAccent : Colors.grey,
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}

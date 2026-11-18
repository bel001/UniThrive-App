import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/schedule.dart';
import '../../core/design_tokens.dart';
import '../../services/calendar_sync_service.dart';
import '../../services/voice_schedule_parser.dart';
import '../../state/app_state.dart';
import '../../utils/platform_capabilities.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/global_search_sheet.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/uni_card.dart';
import '../../widgets/uni_primary_button.dart';
import '../../widgets/uni_supervisual.dart';
import '../../widgets/voice_schedule_sheet.dart';
import '../alarms/alarm_screen.dart';

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
  final VoiceScheduleParser _scheduleParser = const VoiceScheduleParser();

  @override
  Widget build(BuildContext context) {
    final appState = AppStateProvider.of(context);
    final blocks = appState.blocksForDay(_selectedDay);
    final startOfWeek = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    ).subtract(Duration(days: _selectedDay.weekday - 1));
    final weekBlocks = appState.blocksForRange(
      startOfWeek,
      startOfWeek.add(const Duration(days: 7)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Horario Semanal'),
        actions: [
          IconButton(
            tooltip: 'Hoy',
            icon: const Icon(Icons.today_rounded),
            onPressed: () => setState(() {
              _selectedDay = DateTime.now();
              _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
            }),
          ),
          IconButton(
            tooltip: 'Dictar horario',
            icon: const Icon(Icons.mic_rounded),
            onPressed: () => _openVoiceSchedule(context),
          ),
          PopupMenuButton<_CalendarAction>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) => _handleCalendarAction(action, appState),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _CalendarAction.organize,
                child: Text('Organízate'),
              ),
              PopupMenuItem(
                value: _CalendarAction.search,
                child: Text('Buscar'),
              ),
              PopupMenuItem(
                value: _CalendarAction.alarm,
                child: Text('Alarmas'),
              ),
              PopupMenuItem(
                value: _CalendarAction.sync,
                child: Text('Sincronizar'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendarControls(),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _monthlyView
                  ? KeyedSubtree(
                      key: const ValueKey('monthly'),
                      child: _buildMonthGrid(appState.blocksForMonth(_focusedMonth)),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('weekly'),
                      child: _buildWeekBody(blocks, weekBlocks),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add),
          onPressed: () => _showClassSheet(appState: appState),
        ),
      ),
    );
  }

  Widget _buildCalendarControls() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              // Segmented Control estilo pill Vivid Academic Night.
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? DesignTokens.cardDark
                        : theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusLarge,
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildSegmentButton(
                        label: 'Semana',
                        isSelected: !_monthlyView,
                        onTap: () => setState(() => _monthlyView = false),
                        theme: theme,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 4),
                      _buildSegmentButton(
                        label: 'Mes',
                        isSelected: _monthlyView,
                        onTap: () => setState(() => _monthlyView = true),
                        theme: theme,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Toggle Weekends
              Tooltip(
                message: _hideWeekends ? 'Mostrar fines de semana' : 'Ocultar fines de semana',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                    onTap: () => setState(() => _hideWeekends = !_hideWeekends),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _hideWeekends
                            ? theme.colorScheme.primary
                            : (isDark
                                  ? DesignTokens.cardDark
                                  : theme.colorScheme.surfaceContainer),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMedium,
                        ),
                        border: Border.all(
                          color: _hideWeekends
                              ? DesignTokens.accentDeep
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : theme.colorScheme.outlineVariant),
                        ),
                      ),
                      child: Icon(
                        _hideWeekends ? Icons.weekend : Icons.weekend_outlined,
                        size: 20,
                        color: _hideWeekends
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
            border: Border.all(
              color: isSelected
                  ? DesignTokens.accentDeep
                  : Colors.transparent,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekBody(
    List<ScheduleBlock> blocks,
    List<ScheduleBlock> weekBlocks,
  ) {
    final appState = AppStateProvider.of(context);
    final normalized = _uniqueBlocks(blocks)
      ..sort((a, b) => a.start.compareTo(b.start));
    final conflictColors = _conflictHighlights(normalized);

    return ListView(
      padding: const EdgeInsets.only(bottom: 128),
      children: [
        _buildWeekLoadStrip(weekBlocks),
        const SizedBox(height: 8),
        _buildDaySelector(weekBlocks),
        const SizedBox(height: 12),
        if (normalized.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: EmptyStateWidget(
              emoji: '📅',
              title: 'Día sin bloques',
              subtitle:
                  'Puedes dictar tu horario, pegar texto del syllabus o crear una clase manual desde el calendario.',
              buttonText: 'DICTAR HORARIO',
              onButtonPressed: () => _openVoiceSchedule(context),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: normalized.map((block) {
                final allowDurationEdit = _canStretchDuration(block);
                return _ScheduleCard(
                  block: block,
                  onEdit: () =>
                      _showClassSheet(appState: appState, block: block),
                  onDelete: () => appState.removeScheduleBlock(block.id),
                  onReschedule: () => _rescheduleBlock(block),
                  onDuplicate: () {
                    final copy = appState.duplicateScheduleBlock(block.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          copy == null
                              ? 'No se pudo duplicar este bloque.'
                              : 'Bloque duplicado para la próxima semana.',
                        ),
                      ),
                    );
                  },
                  onAdjustDuration: allowDurationEdit
                      ? () => _adjustBlockDuration(block)
                      : null,
                  conflictColor: conflictColors[block.id],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  /// Franja supervisual: carga de bloques por día de la semana visible.
  /// Estilo Vivid Academic Night: card radio 24, barras compartidas,
  /// barra de progreso con gloss y avisos de carga alta / día libre.
  Widget _buildWeekLoadStrip(List<ScheduleBlock> weekBlocks) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final startOfWeek = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    ).subtract(Duration(days: _selectedDay.weekday - 1));
    final counts = List.generate(7, (index) {
      final day = startOfWeek.add(Duration(days: index));
      return weekBlocks
          .where(
            (block) =>
                block.start.year == day.year &&
                block.start.month == day.month &&
                block.start.day == day.day,
          )
          .length;
    });
    final total = counts.fold<int>(0, (sum, value) => sum + value);
    final maxDay = counts.fold<int>(0, (max, value) => value > max ? value : max);
    final heavyIndex = counts.indexWhere((value) => value >= 3);
    final freeIndex = counts.indexWhere((value) => value == 0);
    const dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: UniCard(
        radius: DesignTokens.radiusLarge,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Carga de la semana',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.mint.withValues(
                      alpha: isDark ? 0.16 : 0.22,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$total bloques',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isDark
                          ? DesignTokens.mint
                          : DesignTokens.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            UniMiniBarChart(
              values: counts,
              labels: UniMiniBarChart.weekLabels,
              highlightLast: false,
              height: 84,
              semanticUnit: 'bloques',
            ),
            const SizedBox(height: 8),
            ProgressBar(
              value: total / 14.0,
              fillColor: isDark
                  ? DesignTokens.mintStrong
                  : theme.colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              total == 0
                  ? 'Semana despejada, sin bloques.'
                  : 'Llevas $total bloques esta semana.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (heavyIndex >= 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? DesignTokens.errorContainerDark.withValues(alpha: 0.45)
                      : theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: isDark
                          ? DesignTokens.errorDark
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Carga alta el ${dayNames[heavyIndex]}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Tienes $maxDay bloques ese día. Conviene adelantar algo.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (freeIndex >= 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DesignTokens.mint.withValues(alpha: isDark ? 0.10 : 0.18),
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusMedium,
                  ),
                  border: Border.all(
                    color: DesignTokens.mintStrong.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.celebration_outlined,
                      color: isDark
                          ? DesignTokens.mint
                          : DesignTokens.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Respiro el ${dayNames[freeIndex]}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Ese día está libre. Ideal para descansar o repasar.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleCalendarAction(_CalendarAction action, AppState appState) {
    switch (action) {
      case _CalendarAction.organize:
        _promptOrganize(appState);
        break;
      case _CalendarAction.search:
        showGlobalSearchSheet(context);
        break;
      case _CalendarAction.voice:
        _openVoiceSchedule(context);
        break;
      case _CalendarAction.sync:
        _openCalendarSync(context, appState);
        break;
      case _CalendarAction.alarm:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AlarmScreen()),
        );
        break;
    }
  }



  /// Selector de días estilo Vivid Academic Night: pills verticales de
  /// 72x96 con radio 24 (día + número + dot). El día activo va en índigo.
  Widget _buildDaySelector(List<ScheduleBlock> weekBlocks) {
    const weekDays = ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final startOfWeek = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    ).subtract(Duration(days: _selectedDay.weekday - 1));
    bool hasEvents(int weekday) {
      final day = startOfWeek.add(Duration(days: weekday - 1));
      return weekBlocks.any(
        (block) =>
            block.start.year == day.year &&
            block.start.month == day.month &&
            block.start.day == day.day,
      );
    }

    return SizedBox(
      height: 104,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          final dot = hasEvents(weekday);
          return GestureDetector(
            onTap: () => setState(() {
              _selectedDay = day;
              _focusedMonth = DateTime(day.year, day.month);
            }),
            child: Semantics(
              label: '${weekDays[index]} ${day.day}',
              selected: isSelected,
              button: true,
              child: Container(
                width: 72,
                height: 96,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark
                            ? DesignTokens.cardDark
                            : theme.colorScheme.surfaceContainerLow),
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusLarge,
                  ),
                  border: Border.all(
                    color: isSelected
                        ? DesignTokens.accentDeep
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : theme.colorScheme.outlineVariant),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      weekDays[index],
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.85)
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${day.day}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: !dot
                            ? Colors.transparent
                            : isSelected
                            ? DesignTokens.mint
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildMonthGrid(List<ScheduleBlock> allBlocks) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? DesignTokens.lilac
                      : theme.colorScheme.primary,
                ),
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
                        ? theme.colorScheme.primary.withValues(
                            alpha: isDark ? 0.28 : 0.14,
                          )
                        : (isDark
                              ? DesignTokens.cardDark
                              : theme.colorScheme.surfaceContainerLow),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : theme.dividerColor.withValues(alpha: 0.2)),
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
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        final sheetDark = sheetTheme.brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: sheetDark
                ? DesignTokens.cardDark
                : sheetTheme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border.all(
              color: sheetDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : sheetTheme.colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: sheetTheme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                // Hero estilo detalle de clase: chip + título en lila.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: sheetTheme.colorScheme.primary.withValues(
                      alpha: 0.16,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${events.length} bloque${events.length == 1 ? '' : 's'}',
                    style: sheetTheme.textTheme.labelMedium?.copyWith(
                      color: sheetDark
                          ? DesignTokens.lilac
                          : sheetTheme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Agenda del ${day.day}/${day.month}',
                  style: sheetTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: sheetDark
                        ? DesignTokens.lilac
                        : sheetTheme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                ...events.map(
                  (event) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sheetDark
                          ? DesignTokens.cardDarkAlt
                          : sheetTheme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMedium,
                      ),
                      border: Border.all(
                        color: sheetDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : sheetTheme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: event.color.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event.start.hour.toString().padLeft(2, '0'),
                            style: sheetTheme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: sheetTheme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${_timeWindowLabel(event)} · ${event.location}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: sheetTheme.textTheme.bodySmall?.copyWith(
                                  color: sheetTheme
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: sheetTheme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                UniPrimaryButton(
                  label: 'Ver día completo',
                  onPressed: () {
                    setState(() {
                      _selectedDay = day;
                      _monthlyView = false;
                    });
                    Navigator.of(sheetContext).pop();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
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

  DateTime startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

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
                  final startOfWeek = DateTime(
                    _selectedDay.year,
                    _selectedDay.month,
                    _selectedDay.day,
                  ).subtract(Duration(days: _selectedDay.weekday - 1));
                  final weekBlocks = appState.blocksForRange(
                    startOfWeek,
                    startOfWeek.add(const Duration(days: 7)),
                  );
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
              ListTile(
                leading: const Icon(Icons.notes_rounded),
                title: const Text('Importar desde texto'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _promptImportText(context, appState);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _promptImportIcs(BuildContext context, AppState appState) async {
    final source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder_open_rounded),
              title: const Text('Elegir archivo .ics'),
              subtitle: const Text('Selecciona el archivo exportado'),
              onTap: () => Navigator.of(sheetContext).pop('file'),
            ),
            ListTile(
              leading: const Icon(Icons.notes_rounded),
              title: const Text('Pegar contenido'),
              subtitle: const Text('Copia y pega el texto del calendario'),
              onTap: () => Navigator.of(sheetContext).pop('paste'),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    String? content;
    if (source == 'file') {
      content = await _pickIcsFileContent();
      if (!context.mounted) return;
      if (content == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó ningún archivo .ics.')),
        );
        return;
      }
    } else {
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
        content = controller.text;
      }
      if (!context.mounted) return;
    }

    if (content == null || content.trim().isEmpty) return;
    final imported = await CalendarSyncService.importIcs(content, appState);
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

  Future<String?> _pickIcsFileContent() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ics'],
        withData: true,
      );
      final file = result?.files.single;
      if (file == null) return null;
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        return utf8.decode(file.bytes!, allowMalformed: true);
      }
      final path = file.path;
      if (path != null && path.isNotEmpty) {
        return File(path).readAsString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _promptImportText(
    BuildContext context,
    AppState appState,
  ) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pegar horario en texto'),
        content: TextField(
          controller: controller,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText:
                'Una línea por clase.\nEj:\nFísica lunes y miércoles de 8 a 10 en aula B203 hasta julio',
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
      ),
    );
    if (confirmed != true || controller.text.trim().isEmpty) return;

    var imported = 0;
    final lines = controller.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    for (final line in lines) {
      final draft = _scheduleParser.parse(line, referenceTime: _selectedDay);
      if (!draft.canSave) continue;
      final weekDays = [...draft.weekDays]..sort();
      final anchorStart = weekDays.contains(draft.firstStart.weekday)
          ? draft.firstStart
          : _dateForWeekday(weekDays.first, reference: draft.firstStart);
      final duration = draft.firstEnd.difference(draft.firstStart);
      appState.addScheduleBlock(
        title: draft.title,
        start: anchorStart,
        end: anchorStart.add(duration),
        color: const Color(0xFF85D1F7),
        location: draft.location,
        category: ScheduleCategory.classSession,
        recurrence: weekDays.length > 1
            ? RecurrenceType.custom
            : RecurrenceType.weekly,
        recurrenceEndDate: draft.recurrenceEndDate,
        recurrenceGroupId: weekDays.length > 1
            ? 'text-series-${DateTime.now().millisecondsSinceEpoch}-$imported'
            : null,
        customWeekDays: weekDays.length > 1 ? weekDays : null,
      );
      imported++;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          imported == 0
              ? 'No pude interpretar las líneas pegadas.'
              : 'Importadas $imported clase(s) desde texto.',
        ),
      ),
    );
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
    final bool editingCustomSeries =
        editingBlock?.recurrence == RecurrenceType.custom &&
        (editingBlock?.customWeekDays?.isNotEmpty ?? false);
    final Set<int> selectedDays = editingBlock == null
        ? {_selectedDay.weekday}
        : {
            ...(editingCustomSeries
                ? (editingBlock.customWeekDays ?? [editingBlock.start.weekday])
                : [editingBlock.start.weekday]),
          };
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDarkSheet = theme.brightness == Brightness.dark;
        final fieldFill = isDarkSheet
            ? DesignTokens.cardDarkAlt
            : theme.colorScheme.surfaceContainerLow;
        final borderColor = isDarkSheet
            ? DesignTokens.surfaceVariantDark
            : theme.colorScheme.outlineVariant;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Material(
              color: isDarkSheet
                  ? DesignTokens.backgroundDark
                  : theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEditing ? 'Editar clase' : 'Nuevo evento',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDarkSheet
                                  ? DesignTokens.lilac
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _LabeledField(
                      label: 'Título del evento',
                      controller: nameController,
                      hint: 'Ej. Álgebra Lineal',
                      icon: Icons.edit_outlined,
                      fillColor: fieldFill,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 12),
                    _LabeledField(
                      label: 'Ubicación o enlace',
                      controller: locationController,
                      hint: 'Ej. Edificio B, Aula 101',
                      icon: Icons.location_on_outlined,
                      fillColor: fieldFill,
                      borderColor: borderColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Categoría',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _CategoryRadioCard(
                          label: 'Clase',
                          icon: Icons.school_outlined,
                          selected:
                              sheetCategory == ScheduleCategory.classSession,
                          onTap: () => setSheetState(
                            () => sheetCategory = ScheduleCategory.classSession,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _CategoryRadioCard(
                          label: 'Estudio',
                          icon: Icons.menu_book_outlined,
                          selected: sheetCategory == ScheduleCategory.task,
                          onTap: () => setSheetState(
                            () => sheetCategory = ScheduleCategory.task,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _CategoryRadioCard(
                          label: 'Social',
                          icon: Icons.group_outlined,
                          selected: sheetCategory == ScheduleCategory.event,
                          onTap: () => setSheetState(
                            () => sheetCategory = ScheduleCategory.event,
                          ),
                        ),
                      ],
                    ),
                    if (sheetCategory == ScheduleCategory.project) ...[
                      const SizedBox(height: 8),
                      _CategoryRadioCard(
                        label: 'Proyecto / Enfoque',
                        icon: Icons.hotel_class_outlined,
                        selected: true,
                        onTap: () {},
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(isEditing ? 'Día' : 'Días'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      children: List.generate(7, (index) {
                        const labels = ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'];
                        final weekday = index + 1;
                        final active = isEditing
                            ? (editingCustomSeries
                                  ? selectedDays.contains(weekday)
                                  : selectedDay == weekday)
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
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: isDarkSheet
                              ? DesignTokens.cardDarkAlt
                              : theme.colorScheme.surfaceContainerLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: active
                                  ? DesignTokens.accentDeep
                                  : (isDarkSheet
                                        ? DesignTokens.surfaceVariantDark
                                        : theme.colorScheme.outlineVariant),
                            ),
                          ),
                          onSelected: (_) => setSheetState(() {
                            if (isEditing) {
                              if (editingCustomSeries) {
                                if (active && selectedDays.length > 1) {
                                  selectedDays.remove(weekday);
                                } else if (!active) {
                                  selectedDays.add(weekday);
                                }
                              } else {
                                selectedDay = weekday;
                              }
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
                    Material(
                      color: Colors.transparent,
                      child: ListTile(
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
                    ),
                    const SizedBox(height: 8),
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
                            label: 'Guardar evento',
                            icon: Icons.check_circle_outline_rounded,
                            onPressed: () {
                              final title = nameController.text.trim();
                              if (title.isEmpty) return;
                              final location =
                                  locationController.text.trim().isEmpty
                                  ? 'Edificio B, Aula 101'
                                  : locationController.text.trim();
                              if (editingBlock != null) {
                                final effectiveDays = editingCustomSeries
                                    ? (selectedDays.isEmpty
                                          ? {editingBlock.start.weekday}
                                          : selectedDays)
                                    : {selectedDay};
                                final anchorWeekday =
                                    effectiveDays.contains(
                                      editingBlock.start.weekday,
                                    )
                                    ? editingBlock.start.weekday
                                    : (effectiveDays.toList()..sort()).first;
                                final date = _dateForWeekday(
                                  anchorWeekday,
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
                                  recurrence: editingCustomSeries
                                      ? (effectiveDays.length > 1
                                            ? RecurrenceType.custom
                                            : RecurrenceType.weekly)
                                      : selectedRecurrence,
                                  recurrenceEndDate: recurrenceEndDate,
                                  clearRecurrenceEndDate:
                                      recurrenceEndDate == null,
                                  recurrenceInterval: editingCustomSeries
                                      ? 1
                                      : recurrenceInterval,
                                  customWeekDays: editingCustomSeries
                                      ? (effectiveDays.toList()..sort())
                                      : editingBlock.customWeekDays,
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  DateTime _dateForWeekday(int weekday, {DateTime? reference}) {
    final base = reference ?? _selectedDay;
    return base.add(Duration(days: weekday - base.weekday));
  }

  void _openVoiceSchedule(BuildContext context) {
    if (!PlatformCapabilities.supportsVoiceInput) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El dictado por voz está disponible en Android e iOS.'),
        ),
      );
      return;
    }
    showVoiceScheduleSheet(context, referenceDay: _selectedDay);
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
  final VoidCallback onDuplicate;
  final Color? conflictColor;
  final VoidCallback? onAdjustDuration;
  const _ScheduleCard({
    required this.block,
    required this.onEdit,
    required this.onDelete,
    required this.onReschedule,
    required this.onDuplicate,
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
    final hasConflict = conflictColor != null;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? DesignTokens.cardDark
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(
          color: hasConflict
              ? (conflictColor ?? theme.colorScheme.error)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : theme.colorScheme.outlineVariant),
        ),
        boxShadow: isDark
            ? DesignTokens.cardShadowDark(0.14)
            : DesignTokens.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (hasConflict)
                  Container(
                    width: 6,
                    constraints: const BoxConstraints(minHeight: 76),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: conflictColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                Container(
                  width: 6,
                  constraints: const BoxConstraints(minHeight: 76),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: block.color,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chip de hora estilo bento.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: isDark ? 0.22 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$time – $end',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? DesignTokens.lilac
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        block.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              block.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: block.color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _categoryLabel(block.category),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : block.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 28,
                  ),
                  tooltip: 'Opciones',
                  onPressed: () => _showBlockActions(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBlockActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);
        final sheetDark = sheetTheme.brightness == Brightness.dark;
        Widget actionTile({
          required IconData icon,
          required String title,
          required VoidCallback onTap,
          Color? iconColor,
          Color? titleColor,
        }) {
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (iconColor ?? sheetTheme.colorScheme.primary).withValues(
                  alpha: 0.14,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? sheetTheme.colorScheme.primary),
            ),
            title: Text(
              title,
              style: sheetTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: sheetTheme.colorScheme.onSurfaceVariant,
            ),
            onTap: onTap,
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: sheetDark
                ? DesignTokens.cardDark
                : sheetTheme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border.all(
              color: sheetDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : sheetTheme.colorScheme.outlineVariant,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: sheetTheme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    child: Text(
                      block.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: sheetTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: sheetDark
                            ? DesignTokens.lilac
                            : sheetTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                  actionTile(
                    icon: Icons.edit_outlined,
                    title: 'Editar clase',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onEdit();
                    },
                  ),
                  actionTile(
                    icon: Icons.schedule_outlined,
                    title: 'Reprogramar',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onReschedule();
                    },
                  ),
                  actionTile(
                    icon: Icons.copy_all_rounded,
                    title: 'Duplicar la próxima semana',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onDuplicate();
                    },
                  ),
                  if (onAdjustDuration != null)
                    actionTile(
                      icon: Icons.timer_outlined,
                      title: 'Cambiar duración',
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        onAdjustDuration?.call();
                      },
                    ),
                  actionTile(
                    icon: Icons.delete_outline,
                    title: 'Eliminar',
                    iconColor: sheetTheme.colorScheme.error,
                    titleColor: sheetTheme.colorScheme.error,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onDelete();
                    },
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

enum _OrganizeScope { day, month }

enum _CalendarAction { organize, search, voice, sync, alarm }

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
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      final sheetTheme = Theme.of(context);
      final sheetDark = sheetTheme.brightness == Brightness.dark;
      RecurrenceType selectedType = currentType;
      int selectedInterval =
          currentInterval > 1 ? currentInterval : 1;
      Map<String, dynamic> buildResult() => {
        'type': selectedType,
        'interval':
            selectedType == RecurrenceType.daily ||
                selectedType == RecurrenceType.weekly ||
                selectedType == RecurrenceType.monthly
            ? selectedInterval
            : 1,
      };
      bool isPeriodic(RecurrenceType type) =>
          type == RecurrenceType.daily ||
          type == RecurrenceType.weekly ||
          type == RecurrenceType.monthly;

      return StatefulBuilder(
        builder: (context, setState) {
          String unitLabel() {
            switch (selectedType) {
              case RecurrenceType.daily:
                return selectedInterval == 1 ? 'día' : 'días';
              case RecurrenceType.weekly:
                return selectedInterval == 1 ? 'semana' : 'semanas';
              default:
                return selectedInterval == 1 ? 'mes' : 'meses';
            }
          }

          return SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: sheetDark
                    ? DesignTokens.cardDark
                    : sheetTheme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: sheetDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : sheetTheme.colorScheme.outlineVariant,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: sheetTheme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Text(
                      'Repetir',
                      style: sheetTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: sheetDark
                            ? DesignTokens.lilac
                            : sheetTheme.colorScheme.primary,
                      ),
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
                      setState(() => selectedType = RecurrenceType.daily);
                    },
                  ),
                  _RecurrenceOption(
                    label: 'Todas las semanas',
                    selected: selectedType == RecurrenceType.weekly,
                    onTap: () {
                      setState(() => selectedType = RecurrenceType.weekly);
                    },
                  ),
                  _RecurrenceOption(
                    label: 'Todos los meses',
                    selected: selectedType == RecurrenceType.monthly,
                    onTap: () {
                      setState(() => selectedType = RecurrenceType.monthly);
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
                  if (isPeriodic(selectedType)) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          onPressed: selectedInterval > 1
                              ? () => setState(
                                  () => selectedInterval -= 1,
                                )
                              : null,
                          icon: const Icon(Icons.remove_rounded),
                          tooltip: 'Menos',
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Cada $selectedInterval ${unitLabel()}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton.filledTonal(
                          onPressed: selectedInterval < 30
                              ? () => setState(
                                  () => selectedInterval += 1,
                                )
                              : null,
                          icon: const Icon(Icons.add_rounded),
                          tooltip: 'Más',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                    const SizedBox(height: 12),
                    UniPrimaryButton(
                      label: 'Listo',
                      onPressed: () => Navigator.pop(context, buildResult()),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
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
  final IconData? icon;
  final Color? fillColor;
  final Color? borderColor;
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.icon,
    this.fillColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedFill =
        fillColor ??
        (isDark
            ? DesignTokens.cardDarkAlt
            : theme.colorScheme.surfaceContainerLow);
    final resolvedBorder =
        borderColor ??
        (isDark
            ? DesignTokens.surfaceVariantDark
            : theme.colorScheme.outlineVariant);
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
            prefixIcon: icon == null
                ? null
                : Icon(icon, color: theme.colorScheme.primary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
              borderSide: BorderSide(color: resolvedBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Radio-card de categoría estilo Nuevo Evento (mockup vivid academic):
/// icono + etiqueta, seleccionada en índigo con borde profundo.
class _CategoryRadioCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryRadioCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : (isDark
                      ? DesignTokens.cardDarkAlt
                      : theme.colorScheme.surfaceContainerLow),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            border: Border.all(
              color: selected
                  ? DesignTokens.accentDeep
                  : (isDark
                        ? DesignTokens.surfaceVariantDark
                        : theme.colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
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
        fillColor ??
        (isDark
            ? DesignTokens.cardDarkAlt
            : theme.colorScheme.surfaceContainerLow);
    final resolvedBorder =
        borderColor ??
        (isDark
            ? DesignTokens.surfaceVariantDark
            : theme.colorScheme.outlineVariant);
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
              borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
              color: resolvedFill,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value.format(context),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
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
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      trailing: selected
          ? Icon(
              Icons.check_circle_rounded,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}

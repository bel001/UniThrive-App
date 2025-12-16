import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../models/task.dart';

class SmartPlanner {
  // Working hours: 8:00 AM to 10:00 PM
  static const int startHour = 8;
  static const int endHour = 22;

  /// Finds free time slots for a given day, respecting existing blocks.
  /// Returns a list of available [DateTimeRange]s.
  static List<DateTimeRange> findFreeSlots(
    DateTime date,
    List<ScheduleBlock> existingBlocks,
  ) {
    // 1. Define the working day range
    final dayStart = DateTime(date.year, date.month, date.day, startHour);
    final dayEnd = DateTime(date.year, date.month, date.day, endHour);

    // 2. Filter blocks for this day and sort by start time
    final blocksForDay = existingBlocks.where((b) {
      return b.start.year == date.year &&
          b.start.month == date.month &&
          b.start.day == date.day;
    }).toList()..sort((a, b) => a.start.compareTo(b.start));

    List<DateTimeRange> freeSlots = [];
    DateTime currentPointer = dayStart;

    // 3. Iterate through blocks to find gaps
    for (final block in blocksForDay) {
      // If the block starts after the current pointer, we have a gap
      if (block.start.isAfter(currentPointer)) {
        // Ensure the gap is within working hours (it should be if sorted correctly)
        // Also check if gap is big enough? (e.g. > 15 mins). For now, take all.
        if (block.start.isBefore(dayEnd)) {
          freeSlots.add(DateTimeRange(start: currentPointer, end: block.start));
        } else {
          // Block starts after day end, so the gap goes until dayEnd
          freeSlots.add(DateTimeRange(start: currentPointer, end: dayEnd));
          currentPointer = dayEnd; // Stop processing
          break;
        }
      }

      // Move pointer to end of current block, if it's later than current pointer
      if (block.end.isAfter(currentPointer)) {
        currentPointer = block.end;
      }
    }

    // 4. Check for remaining time after the last block until dayEnd
    if (currentPointer.isBefore(dayEnd)) {
      freeSlots.add(DateTimeRange(start: currentPointer, end: dayEnd));
    }

    return freeSlots;
  }

  /// Distributes tasks into available slots.
  /// Returns a list of new [ScheduleBlock]s.
  static List<ScheduleBlock> distributeTasks({
    required List<Task> tasks,
    required List<ScheduleBlock> existingBlocks,
    required DateTime startDate,
    int daysToPlan = 7,
  }) {
    List<ScheduleBlock> newBlocks = [];
    List<Task> pendingTasks = List.from(tasks);

    // Sort tasks by priority/deadline? For now, just take them in order.

    for (int i = 0; i < daysToPlan; i++) {
      if (pendingTasks.isEmpty) break;

      final currentDate = startDate.add(Duration(days: i));

      // Skip weekends? Maybe make it optional. For now, include them.

      final freeSlots = findFreeSlots(currentDate, existingBlocks);

      for (final slot in freeSlots) {
        if (pendingTasks.isEmpty) break;

        Duration slotDuration = slot.duration;
        DateTime slotStart = slot.start;

        // Try to fit tasks into this slot
        while (pendingTasks.isNotEmpty && slotDuration.inMinutes >= 30) {
          final task = pendingTasks.first;
          // Estimate task duration (default 60 mins if not set?)
          // Or use a fixed block size (e.g. 60 mins)
          const int blockMinutes = 60;

          if (slotDuration.inMinutes >= blockMinutes) {
            // Create a block
            final blockEnd = slotStart.add(
              const Duration(minutes: blockMinutes),
            );

            newBlocks.add(
              ScheduleBlock(
                id:
                    DateTime.now().millisecondsSinceEpoch.toString() +
                    i.toString(), // Simple ID gen
                title: 'Estudiar: ${task.title}',
                start: slotStart,
                end: blockEnd,
                category: ScheduleCategory.task,
                linkedTaskId: task.id,
                color: const Color(0xFF9FCFBB), // Example color
              ),
            );

            // Remove task from pending (or mark as scheduled?)
            // If task takes longer, maybe we only schedule a part of it?
            // For this MVP, assume 1 block = 1 task done or progress.
            pendingTasks.removeAt(0);

            // Update slot
            slotStart = blockEnd;
            slotDuration -= const Duration(minutes: blockMinutes);
          } else {
            // Slot too small for a full block, move to next slot
            break;
          }
        }
      }
    }

    return newBlocks;
  }

  /// Generates a list of template tasks based on project type and size.
  static List<String> generateTasksForProject(
    // We'll use String for size for now, matching the UI ('Pequeño', 'Mediano', 'Grande')
    String size,
    // We need ProjectType enum, but it's in project.dart.
    // We can pass it as int or string if we don't want to import project.dart here,
    // but better to import it.
    // Assuming we import '../models/project.dart';
    dynamic type,
  ) {
    // Basic templates
    final small = [
      'Investigación inicial',
      'Esquema básico',
      'Desarrollo',
      'Revisión final',
    ];
    final medium = [
      'Investigación profunda',
      'Borrador de estructura',
      'Desarrollo parte 1',
      'Desarrollo parte 2',
      'Revisión y corrección',
      'Entrega final',
    ];
    final large = [
      'Planificación y cronograma',
      'Investigación exhaustiva',
      'Borrador inicial',
      'Desarrollo fase 1',
      'Desarrollo fase 2',
      'Desarrollo fase 3',
      'Revisión de pares/auto-revisión',
      'Pulido final',
      'Preparación de entrega',
    ];

    List<String> baseTasks;
    if (size == 'Pequeño') {
      baseTasks = small;
    } else if (size == 'Mediano') {
      baseTasks = medium;
    } else {
      baseTasks = large;
    }

    // We could customize based on type (Essay, Presentation, etc.)
    // For now, just return the base tasks with some prefix/suffix if needed.
    return baseTasks;
  }
}

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/schedule.dart';
import '../state/app_state.dart';

class CalendarSyncService {
  CalendarSyncService._();

  static Future<void> exportBlocks({
    required BuildContext context,
    required List<ScheduleBlock> blocks,
    required String fileName,
    String? description,
  }) async {
    if (blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay eventos para exportar.')),
      );
      return;
    }
    final ics = _buildIcs(blocks);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(ics);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: description ?? 'Importa este calendario en tu app favorita.');
  }

  static Future<int> importIcs(String icsContent, AppState appState) async {
    final events = _parseEvents(icsContent);
    int imported = 0;
    for (final event in events) {
      final existing = appState.scheduleBlocks.any(
        (block) =>
            block.title == event.title &&
            (event.start != null ? block.start == event.start : false),
      );
      if (existing) continue;
      final start = event.start ?? DateTime.now();
      final normalizedEnd = event.end.isAfter(start)
          ? event.end
          : start.add(const Duration(hours: 1));
      appState.addScheduleBlock(
        title: event.title,
        start: start,
        end: normalizedEnd,
        color: event.color,
        location: event.location,
        category: ScheduleCategory.event,
      );
      imported++;
    }
    return imported;
  }

  static String _buildIcs(List<ScheduleBlock> blocks) {
    final buffer = StringBuffer()
      ..writeln('BEGIN:VCALENDAR')
      ..writeln('VERSION:2.0')
      ..writeln('PRODID:-//UniThrive//ES');
    for (final block in blocks) {
      buffer
        ..writeln('BEGIN:VEVENT')
        ..writeln('UID:${block.id}@unithrive')
        ..writeln('SUMMARY:${block.title}')
        ..writeln('DTSTART:${_formatDate(block.start)}')
        ..writeln('DTEND:${_formatDate(block.end)}')
        ..writeln('LOCATION:${block.location}')
        ..writeln('END:VEVENT');
    }
    buffer.writeln('END:VCALENDAR');
    return buffer.toString();
  }

  static String _formatDate(DateTime dt) {
    final utc = dt.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final h = utc.hour.toString().padLeft(2, '0');
    final min = utc.minute.toString().padLeft(2, '0');
    final sec = utc.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${sec}Z';
  }

  static List<_IcsEvent> _parseEvents(String content) {
    final matches = RegExp(
      r'BEGIN:VEVENT(.*?)END:VEVENT',
      dotAll: true,
    ).allMatches(content);
    final random = Random();
    final events = <_IcsEvent>[];
    for (final match in matches) {
      final raw = match.group(1) ?? '';
      final summary = _matchValue(raw, 'SUMMARY') ?? 'Evento UniThrive';
      final location = _matchValue(raw, 'LOCATION') ?? 'Sin ubicación';
      final start = _parseDate(_matchValue(raw, 'DTSTART'));
      final end =
          _parseDate(_matchValue(raw, 'DTEND')) ??
          (start ?? DateTime.now()).add(const Duration(hours: 1));
      final color = _palette[random.nextInt(_palette.length)];
      events.add(
        _IcsEvent(
          title: summary,
          location: location,
          start: start,
          end: end,
          color: color,
        ),
      );
    }
    return events;
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    try {
      if (raw.endsWith('Z')) {
        return DateTime.parse(raw);
      }
      return DateTime.parse('${raw}Z').toLocal();
    } catch (_) {
      return null;
    }
  }

  static String? _matchValue(String block, String key) {
    final regex = RegExp('$key(?:;[^:]*)?:(.*)');
    final match = regex.firstMatch(block);
    return match?.group(1)?.trim();
  }

  static const _palette = [
    Color(0xFF9FCFBB),
    Color(0xFFFF5A5F),
    Color(0xFF42C57A),
    Color(0xFF00B2A9),
  ];
}

class _IcsEvent {
  final String title;
  final String location;
  final DateTime? start;
  final DateTime end;
  final Color color;

  const _IcsEvent({
    required this.title,
    required this.location,
    required this.start,
    required this.end,
    required this.color,
  });
}

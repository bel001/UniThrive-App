import 'package:flutter/material.dart';

enum ScheduleCategory { task, project, classSession, event }

enum RecurrenceType {
  none, // No se repite
  daily, // Todos los días
  weekly, // Todas las semanas
  monthly, // Todos los meses
  yearly, // Todos los años
  custom, // Personalización
}

class ScheduleBlock {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final Color color;
  final String location;
  final String? linkedTaskId;
  final ScheduleCategory category;

  // Recurrence fields
  final RecurrenceType recurrence;
  final DateTime?
  recurrenceEndDate; // Fecha límite de repetición (null = sin límite)
  final int recurrenceInterval; // Intervalo de repetición (ej: cada 2 semanas)
  final String? recurrenceGroupId; // ID para agrupar eventos de la misma serie
  final List<int>?
  customWeekDays; // Días de la semana para recurrencia personalizada (1=lun, 7=dom)

  const ScheduleBlock({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.color = const Color(0xFF4D7CFF),
    this.location = 'Edificio B, Aula 101',
    this.linkedTaskId,
    this.category = ScheduleCategory.classSession,
    this.recurrence = RecurrenceType.none,
    this.recurrenceEndDate,
    this.recurrenceInterval = 1,
    this.recurrenceGroupId,
    this.customWeekDays,
  });

  ScheduleBlock copyWith({
    String? title,
    DateTime? start,
    DateTime? end,
    Color? color,
    String? location,
    String? linkedTaskId,
    ScheduleCategory? category,
    RecurrenceType? recurrence,
    DateTime? recurrenceEndDate,
    int? recurrenceInterval,
    String? recurrenceGroupId,
    List<int>? customWeekDays,
  }) {
    return ScheduleBlock(
      id: id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      color: color ?? this.color,
      location: location ?? this.location,
      linkedTaskId: linkedTaskId ?? this.linkedTaskId,
      category: category ?? this.category,
      recurrence: recurrence ?? this.recurrence,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceGroupId: recurrenceGroupId ?? this.recurrenceGroupId,
      customWeekDays: customWeekDays ?? this.customWeekDays,
    );
  }

  factory ScheduleBlock.fromJson(Map<String, dynamic> json) {
    return ScheduleBlock(
      id: json['id'] as String,
      title: json['title'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      color: Color(json['color'] as int),
      location: json['location'] as String? ?? 'Edificio B, Aula 101',
      linkedTaskId: json['linkedTaskId'] as String?,
      category: _categoryFromString(json['category'] as String?),
      recurrence: _recurrenceFromString(json['recurrence'] as String?),
      recurrenceEndDate: json['recurrenceEndDate'] != null
          ? DateTime.parse(json['recurrenceEndDate'] as String)
          : null,
      recurrenceInterval: json['recurrenceInterval'] as int? ?? 1,
      recurrenceGroupId: json['recurrenceGroupId'] as String?,
      customWeekDays: (json['customWeekDays'] as List?)?.cast<int>(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'color': color.toARGB32(),
    'location': location,
    'linkedTaskId': linkedTaskId,
    'category': category.name,
    'recurrence': recurrence.name,
    'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
    'recurrenceInterval': recurrenceInterval,
    'recurrenceGroupId': recurrenceGroupId,
    'customWeekDays': customWeekDays,
  };

  String get recurrenceLabel {
    switch (recurrence) {
      case RecurrenceType.none:
        return 'No se repite';
      case RecurrenceType.daily:
        return recurrenceInterval == 1
            ? 'Todos los días'
            : 'Cada $recurrenceInterval días';
      case RecurrenceType.weekly:
        return recurrenceInterval == 1
            ? 'Todas las semanas'
            : 'Cada $recurrenceInterval semanas';
      case RecurrenceType.monthly:
        return recurrenceInterval == 1
            ? 'Todos los meses'
            : 'Cada $recurrenceInterval meses';
      case RecurrenceType.yearly:
        return 'Todos los años';
      case RecurrenceType.custom:
        return 'Personalizado';
    }
  }
}

ScheduleCategory _categoryFromString(String? value) {
  switch (value) {
    case 'task':
      return ScheduleCategory.task;
    case 'project':
      return ScheduleCategory.project;
    case 'event':
      return ScheduleCategory.event;
    default:
      return ScheduleCategory.classSession;
  }
}

RecurrenceType _recurrenceFromString(String? value) {
  switch (value) {
    case 'daily':
      return RecurrenceType.daily;
    case 'weekly':
      return RecurrenceType.weekly;
    case 'monthly':
      return RecurrenceType.monthly;
    case 'yearly':
      return RecurrenceType.yearly;
    case 'custom':
      return RecurrenceType.custom;
    default:
      return RecurrenceType.none;
  }
}

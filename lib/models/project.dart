import 'package:flutter/material.dart';

class Project {
  final String id;
  final String name;
  final String description;
  final DateTime dueDate;
  final Color color;
  final double progress;
  final bool completed;
  final String tag;
  final bool hidden;
  final ProjectType type;

  const Project({
    required this.id,
    required this.name,
    this.description = '',
    required this.dueDate,
    required this.color,
    this.progress = 0.0,
    this.completed = false,
    this.tag = 'En curso',
    this.hidden = false,
    this.type = ProjectType.general,
  });

  Project copyWith({
    String? name,
    String? description,
    DateTime? dueDate,
    Color? color,
    double? progress,
    bool? completed,
    String? tag,
    bool? hidden,
    ProjectType? type,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      color: color ?? this.color,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
      tag: tag ?? this.tag,
      hidden: hidden ?? this.hidden,
      type: type ?? this.type,
    );
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      dueDate: DateTime.parse(json['dueDate'] as String),
      color: Color(json['color'] as int),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      completed: json['completed'] as bool? ?? false,
      tag: json['tag'] as String? ?? 'En curso',
      hidden: json['hidden'] as bool? ?? false,
      type: ProjectType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'general'),
        orElse: () => ProjectType.general,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'dueDate': dueDate.toIso8601String(),
    'color': color.toARGB32(),
    'progress': progress,
    'completed': completed,
    'tag': tag,
    'hidden': hidden,
    'type': type.name,
  };
}

enum ProjectType {
  essay, // Ensayo / Escrito
  presentation, // Presentación
  development, // Desarrollo / Código
  study, // Estudio / Examen
  creative, // Creativo / Arte
  general, // General
}

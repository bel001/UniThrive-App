class Subtask {
  final String id;
  final String taskId;
  final String title;
  final bool completed;
  final DateTime? completedAt;
  final int order;

  const Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    this.completed = false,
    this.completedAt,
    required this.order,
  });

  Subtask copyWith({
    String? title,
    bool? completed,
    DateTime? completedAt,
    int? order,
  }) {
    return Subtask(
      id: id,
      taskId: taskId,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      order: order ?? this.order,
    );
  }

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'title': title,
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
    'order': order,
  };
}

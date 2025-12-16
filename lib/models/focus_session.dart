class FocusSession {
  final String id;
  final String label;
  final DateTime startTime;
  final DateTime? endTime;

  const FocusSession({
    required this.id,
    required this.label,
    required this.startTime,
    this.endTime,
  });

  bool get isActive => endTime == null;

  Duration get elapsed => (endTime ?? DateTime.now()).difference(startTime);

  FocusSession copyWith({DateTime? endTime}) => FocusSession(
        id: id,
        label: label,
        startTime: startTime,
        endTime: endTime ?? this.endTime,
      );

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        id: json['id'] as String,
        label: json['label'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
      };
}

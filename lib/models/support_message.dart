class SupportMessage {
  final bool fromCoach;
  final String text;
  final DateTime timestamp;
  final String? actionLabel;

  const SupportMessage({
    required this.fromCoach,
    required this.text,
    required this.timestamp,
    this.actionLabel,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
    fromCoach: json['fromCoach'] as bool? ?? false,
    text: json['text'] as String? ?? '',
    timestamp: DateTime.parse(json['timestamp'] as String),
    actionLabel: json['actionLabel'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'fromCoach': fromCoach,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'actionLabel': actionLabel,
  };
}

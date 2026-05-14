class VoiceScheduleDraft {
  final String transcript;
  final String title;
  final String location;
  final DateTime firstStart;
  final DateTime firstEnd;
  final List<int> weekDays;
  final DateTime? recurrenceEndDate;
  final List<String> notes;

  const VoiceScheduleDraft({
    required this.transcript,
    required this.title,
    required this.location,
    required this.firstStart,
    required this.firstEnd,
    required this.weekDays,
    this.recurrenceEndDate,
    this.notes = const [],
  });

  factory VoiceScheduleDraft.empty({DateTime? referenceTime}) {
    final reference = referenceTime ?? DateTime.now();
    final start = DateTime(reference.year, reference.month, reference.day, 9);
    return VoiceScheduleDraft(
      transcript: '',
      title: '',
      location: '',
      firstStart: start,
      firstEnd: start.add(const Duration(hours: 2)),
      weekDays: [reference.weekday],
      notes: const [
        'Dicta el nombre de la clase, los días y el horario para crear una serie semanal.',
      ],
    );
  }

  bool get hasTranscript => transcript.trim().isNotEmpty;
  bool get canSave =>
      title.trim().isNotEmpty &&
      weekDays.isNotEmpty &&
      firstEnd.isAfter(firstStart);

  VoiceScheduleDraft copyWith({
    String? transcript,
    String? title,
    String? location,
    DateTime? firstStart,
    DateTime? firstEnd,
    List<int>? weekDays,
    DateTime? recurrenceEndDate,
    bool clearRecurrenceEndDate = false,
    List<String>? notes,
  }) {
    return VoiceScheduleDraft(
      transcript: transcript ?? this.transcript,
      title: title ?? this.title,
      location: location ?? this.location,
      firstStart: firstStart ?? this.firstStart,
      firstEnd: firstEnd ?? this.firstEnd,
      weekDays: weekDays ?? this.weekDays,
      recurrenceEndDate: clearRecurrenceEndDate
          ? null
          : recurrenceEndDate ?? this.recurrenceEndDate,
      notes: notes ?? this.notes,
    );
  }
}

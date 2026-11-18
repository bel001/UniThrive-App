class VoiceScheduleDraft {
  final String transcript;
  final String title;
  final String location;
  final DateTime firstStart;
  final DateTime firstEnd;
  final List<int> weekDays;
  final DateTime? recurrenceEndDate;
  final bool isSingleEvent;
  final String? linkedProjectId;
  final bool hasConflict;
  final String? conflictMessage;
  final List<String> notes;

  const VoiceScheduleDraft({
    required this.transcript,
    required this.title,
    required this.location,
    required this.firstStart,
    required this.firstEnd,
    required this.weekDays,
    this.recurrenceEndDate,
    this.isSingleEvent = false,
    this.linkedProjectId,
    this.hasConflict = false,
    this.conflictMessage,
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
      isSingleEvent: false,
      notes: const [
        'Dicta el nombre de la clase, días u horario (ej: "Jueves 27 de agosto de 6:00 am a 8:30 pm en aula B203").',
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
    bool? isSingleEvent,
    String? linkedProjectId,
    bool? hasConflict,
    String? conflictMessage,
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
      isSingleEvent: isSingleEvent ?? this.isSingleEvent,
      linkedProjectId: linkedProjectId ?? this.linkedProjectId,
      hasConflict: hasConflict ?? this.hasConflict,
      conflictMessage: conflictMessage ?? this.conflictMessage,
      notes: notes ?? this.notes,
    );
  }
}

class VoiceTaskDraft {
  final String transcript;
  final String title;
  final String? projectHint;
  final String? matchedProjectName;
  final DateTime dueDate;
  final bool dueDateWasInferred;
  final bool dueTimeWasInferred;
  final List<String> notes;

  const VoiceTaskDraft({
    required this.transcript,
    required this.title,
    required this.dueDate,
    this.projectHint,
    this.matchedProjectName,
    this.dueDateWasInferred = false,
    this.dueTimeWasInferred = false,
    this.notes = const [],
  });

  factory VoiceTaskDraft.empty({DateTime? referenceTime}) {
    final now = referenceTime ?? DateTime.now();
    return VoiceTaskDraft(
      transcript: '',
      title: '',
      dueDate: DateTime(now.year, now.month, now.day + 1, 18),
      dueDateWasInferred: true,
      dueTimeWasInferred: true,
    );
  }

  bool get hasTranscript => transcript.trim().isNotEmpty;
  bool get canSave => title.trim().isNotEmpty;

  VoiceTaskDraft copyWith({
    String? transcript,
    String? title,
    String? projectHint,
    String? matchedProjectName,
    DateTime? dueDate,
    bool? dueDateWasInferred,
    bool? dueTimeWasInferred,
    List<String>? notes,
  }) {
    return VoiceTaskDraft(
      transcript: transcript ?? this.transcript,
      title: title ?? this.title,
      projectHint: projectHint ?? this.projectHint,
      matchedProjectName: matchedProjectName ?? this.matchedProjectName,
      dueDate: dueDate ?? this.dueDate,
      dueDateWasInferred: dueDateWasInferred ?? this.dueDateWasInferred,
      dueTimeWasInferred: dueTimeWasInferred ?? this.dueTimeWasInferred,
      notes: notes ?? this.notes,
    );
  }
}

class SubtitleSegment {
  final int index;
  final Duration startTime;
  final Duration endTime;
  final String text;
  final String? activeWord;
  final bool isSelected;
  final Map<String, dynamic>? metadata;

  SubtitleSegment({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.text,
    this.activeWord,
    required this.isSelected,
    this.metadata,
  });

  SubtitleSegment copyWith({
    int? index,
    Duration? startTime,
    Duration? endTime,
    String? text,
    String? activeWord,
    bool? isSelected,
    Map<String, dynamic>? metadata,
  }) {
    return SubtitleSegment(
      index: index ?? this.index,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      text: text ?? this.text,
      activeWord: activeWord ?? this.activeWord,
      isSelected: isSelected ?? this.isSelected,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'startMs': startTime.inMilliseconds,
      'endMs': endTime.inMilliseconds,
      'text': text,
      'activeWord': activeWord,
      'isSelected': isSelected,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory SubtitleSegment.fromJson(Map<String, dynamic> json) {
    return SubtitleSegment(
      index: json['index'] as int? ?? 0,
      startTime: Duration(milliseconds: json['startMs'] as int? ?? 0),
      endTime: Duration(milliseconds: json['endMs'] as int? ?? 0),
      text: json['text'] as String? ?? '',
      activeWord: json['activeWord'] as String?,
      isSelected: json['isSelected'] as bool? ?? false,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

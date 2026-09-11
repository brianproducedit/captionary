class SubtitleSegment {
  final int index;
  final Duration startTime;
  final Duration endTime;
  final String text;
  final String? activeWord;
  final bool isSelected;

  SubtitleSegment({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.text,
    this.activeWord,
    required this.isSelected,
  });

  SubtitleSegment copyWith({
    int? index,
    Duration? startTime,
    Duration? endTime,
    String? text,
    String? activeWord,
    bool? isSelected,
  }) {
    return SubtitleSegment(
      index: index ?? this.index,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      text: text ?? this.text,
      activeWord: activeWord ?? this.activeWord,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

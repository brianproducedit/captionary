String formatPlayerTime(Duration duration) {
  final negative = duration.isNegative;
  final value = duration.abs();
  final hours = value.inHours;
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  final text = hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  return negative ? '-$text' : text;
}

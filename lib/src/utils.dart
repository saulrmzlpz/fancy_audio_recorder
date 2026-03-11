import 'dart:math' as math;

String formatDuration(Duration? duration) {
  if (duration == null) return '00:00';

  String twoDigits(int n) => n.toString().padLeft(2, '0');

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
  return '${twoDigits(minutes)}:${twoDigits(seconds)}';
}

double calculatedDB(double amplitude) {
  const double minDecibels =
      -120.0; // Or use -60dB, which I measured in a silent room.

  if (amplitude < minDecibels) {
    return 0;
  } else if (amplitude >= 0) {
    return 1;
  } else {
    const double root = 2.0;
    final num minAmp = math.pow(10.0, 0.05 * minDecibels);
    final num inverseAmpRange = 1.0 / (1.0 - minAmp);
    final num amp = math.pow(10.0, 0.05 * amplitude);
    final num adjAmp = (amp - minAmp) * inverseAmpRange;

    return math.pow(adjAmp, 1.0 / root).toDouble();
  }
}

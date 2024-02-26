import 'dart:math' as math;

String formatDuration(Duration? duration) {
  if (duration == null) return '';

  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String hours = twoDigits(duration.inHours.remainder(24));
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));

  return "$hours:$minutes:$seconds";
}

double calculatedDB(double amplitude) {
  const double minDecibels = -120.0; // Or use -60dB, which I measured in a silent room.

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

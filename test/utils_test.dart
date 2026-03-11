import 'package:fancy_audio_recorder/src/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDuration', () {
    test('returns 00:00 for null', () {
      expect(formatDuration(null), equals('00:00'));
    });

    test('returns 00:00 for Duration.zero', () {
      expect(formatDuration(Duration.zero), equals('00:00'));
    });

    test('formats seconds only (< 1 minute)', () {
      expect(formatDuration(const Duration(seconds: 5)), equals('00:05'));
      expect(formatDuration(const Duration(seconds: 45)), equals('00:45'));
    });

    test('formats minutes and seconds', () {
      expect(
        formatDuration(const Duration(minutes: 1, seconds: 30)),
        equals('01:30'),
      );
    });

    test('formats hours when duration >= 1 hour', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
        equals('01:02:03'),
      );
    });

    test('omits hours when duration is under 1 hour', () {
      expect(
        formatDuration(const Duration(minutes: 59, seconds: 59)),
        equals('59:59'),
      );
    });

    test('pads single digits with leading zero', () {
      expect(
        formatDuration(const Duration(minutes: 1, seconds: 5)),
        equals('01:05'),
      );
    });

    test('handles exactly 1 hour', () {
      expect(
        formatDuration(const Duration(hours: 1)),
        equals('01:00:00'),
      );
    });
  });

  group('calculatedDB', () {
    test('returns 0 for amplitude below -120 dB', () {
      expect(calculatedDB(-200.0), equals(0.0));
    });

    test('returns 0 for amplitude exactly at -120 dB (minimum)', () {
      expect(calculatedDB(-120.0), equals(0.0));
    });

    test('returns 1 for amplitude at 0 dB', () {
      expect(calculatedDB(0.0), equals(1.0));
    });

    test('returns 1 for positive amplitude (above max)', () {
      expect(calculatedDB(10.0), equals(1.0));
    });

    test('returns value between 0 and 1 for mid-range amplitude', () {
      final result = calculatedDB(-60.0);
      expect(result, greaterThan(0.0));
      expect(result, lessThan(1.0));
    });

    test('higher amplitude returns higher result', () {
      expect(calculatedDB(-30.0), greaterThan(calculatedDB(-60.0)));
      expect(calculatedDB(-60.0), greaterThan(calculatedDB(-90.0)));
    });

    test('result is always a finite double', () {
      for (final db in [-150.0, -120.0, -90.0, -60.0, -30.0, -10.0, 0.0, 5.0]) {
        final result = calculatedDB(db);
        expect(result, isA<double>());
        expect(result.isNaN, isFalse, reason: 'NaN for $db dB');
        expect(result.isInfinite, isFalse, reason: 'Infinite for $db dB');
      }
    });

    test('result is always clamped between 0 and 1', () {
      for (final db in [-150.0, -120.0, -90.0, -60.0, -30.0, -10.0, 0.0, 5.0]) {
        final result = calculatedDB(db);
        expect(result, greaterThanOrEqualTo(0.0));
        expect(result, lessThanOrEqualTo(1.0));
      }
    });
  });
}

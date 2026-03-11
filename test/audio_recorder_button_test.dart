import 'package:fancy_audio_recorder/fancy_audio_recorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioRecorderButton.isInfinite', () {
    test('is true when maxRecordTime is Duration.zero (default)', () {
      const button = AudioRecorderButton();
      expect(button.isInfinite, isTrue);
    });

    test('is true when maxRecordTime is explicitly Duration.zero', () {
      const button = AudioRecorderButton(maxRecordTime: Duration.zero);
      expect(button.isInfinite, isTrue);
    });

    test('is false when maxRecordTime is a positive duration', () {
      const button = AudioRecorderButton(
        maxRecordTime: Duration(seconds: 30),
      );
      expect(button.isInfinite, isFalse);
    });

    test('is false for very short maxRecordTime', () {
      const button = AudioRecorderButton(
        maxRecordTime: Duration(milliseconds: 1),
      );
      expect(button.isInfinite, isFalse);
    });
  });

  group('AudioRecorderButton – default parameter values', () {
    test('maxRecordTime defaults to Duration.zero', () {
      const button = AudioRecorderButton();
      expect(button.maxRecordTime, equals(Duration.zero));
    });

    test('buttonSize defaults to 60', () {
      const button = AudioRecorderButton();
      expect(button.buttonSize, equals(60.0));
    });

    test('showMaxTime defaults to true', () {
      const button = AudioRecorderButton();
      expect(button.showMaxTime, isTrue);
    });

    test('buttonColor defaults to null', () {
      const button = AudioRecorderButton();
      expect(button.buttonColor, isNull);
    });

    test('waveColor defaults to null', () {
      const button = AudioRecorderButton();
      expect(button.waveColor, isNull);
    });

    test('onRecordComplete defaults to null', () {
      const button = AudioRecorderButton();
      expect(button.onRecordComplete, isNull);
    });

    test('onRecordStart defaults to null', () {
      const button = AudioRecorderButton();
      expect(button.onRecordStart, isNull);
    });

    test('onRecordDelete defaults to null', () {
      const button = AudioRecorderButton();
      expect(button.onRecordDelete, isNull);
    });
  });

  group('AudioRecorderButton – showMaxTime logic', () {
    test('showMaxTime is irrelevant when infinite (isInfinite overrides)', () {
      const buttonInfiniteShowTrue = AudioRecorderButton(
        maxRecordTime: Duration.zero,
        showMaxTime: true,
      );
      const buttonInfiniteShowFalse = AudioRecorderButton(
        maxRecordTime: Duration.zero,
        showMaxTime: false,
      );
      // Both are infinite so max time should never show regardless of showMaxTime
      expect(buttonInfiniteShowTrue.isInfinite, isTrue);
      expect(buttonInfiniteShowFalse.isInfinite, isTrue);
    });

    test('showMaxTime can be controlled when not infinite', () {
      const buttonShow = AudioRecorderButton(
        maxRecordTime: Duration(minutes: 2),
        showMaxTime: true,
      );
      const buttonHide = AudioRecorderButton(
        maxRecordTime: Duration(minutes: 2),
        showMaxTime: false,
      );
      expect(buttonShow.showMaxTime, isTrue);
      expect(buttonHide.showMaxTime, isFalse);
      expect(buttonShow.isInfinite, isFalse);
    });
  });

  group('AudioRecorderButton – initial widget render', () {
    testWidgets('renders without error in initial state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AudioRecorderButton(),
            ),
          ),
        ),
      );
      // Should render WaveButton in start state showing mic icon
      expect(find.byType(AudioRecorderButton), findsOneWidget);
      expect(find.byType(WaveButton), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('renders mic icon in initial start state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: AudioRecorderButton()),
          ),
        ),
      );
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('timer is not visible before recording starts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: AudioRecorderButton()),
          ),
        ),
      );
      expect(find.byType(TimerText), findsNothing);
    });

    testWidgets('renders with custom buttonSize', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AudioRecorderButton(buttonSize: 80),
            ),
          ),
        ),
      );
      expect(find.byType(AudioRecorderButton), findsOneWidget);
    });

    testWidgets('renders with custom colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AudioRecorderButton(
                buttonColor: Colors.red,
                waveColor: Colors.blue,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(AudioRecorderButton), findsOneWidget);
    });
  });
}

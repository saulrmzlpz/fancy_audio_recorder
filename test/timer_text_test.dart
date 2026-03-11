import 'package:fancy_audio_recorder/src/audio_recorder_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTimerText({
    Duration elapsed = Duration.zero,
    Duration max = const Duration(minutes: 2),
    bool showMaxTime = true,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: TimerText(
            elapsedTime: elapsed,
            maxRecordTime: max,
            showMaxTime: showMaxTime,
          ),
        ),
      );

  group('TimerText – elapsed time display', () {
    testWidgets('shows 00:00 for Duration.zero', (tester) async {
      await tester.pumpWidget(buildTimerText(elapsed: Duration.zero));
      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('shows formatted elapsed time in mm:ss', (tester) async {
      await tester.pumpWidget(
        buildTimerText(elapsed: const Duration(seconds: 5)),
      );
      expect(find.text('00:05'), findsOneWidget);
    });

    testWidgets('shows formatted elapsed time with minutes', (tester) async {
      await tester.pumpWidget(
        buildTimerText(elapsed: const Duration(minutes: 1, seconds: 30)),
      );
      expect(find.text('01:30'), findsOneWidget);
    });

    testWidgets('updates when elapsed time changes', (tester) async {
      await tester.pumpWidget(
        buildTimerText(elapsed: const Duration(seconds: 10)),
      );
      expect(find.text('00:10'), findsOneWidget);

      await tester.pumpWidget(
        buildTimerText(elapsed: const Duration(seconds: 30)),
      );
      expect(find.text('00:30'), findsOneWidget);
    });
  });

  group('TimerText – max time display', () {
    testWidgets('shows max time when showMaxTime is true', (tester) async {
      await tester.pumpWidget(buildTimerText(
        elapsed: const Duration(seconds: 5),
        max: const Duration(minutes: 2),
        showMaxTime: true,
      ));
      expect(find.text('02:00'), findsOneWidget);
    });

    testWidgets('hides max time when showMaxTime is false', (tester) async {
      await tester.pumpWidget(buildTimerText(
        elapsed: const Duration(seconds: 5),
        max: const Duration(minutes: 2),
        showMaxTime: false,
      ));
      expect(find.text('02:00'), findsNothing);
    });

    testWidgets('shows "/" separator when showMaxTime is true', (tester) async {
      await tester.pumpWidget(buildTimerText(showMaxTime: true));
      expect(find.text('/'), findsOneWidget);
    });

    testWidgets('hides "/" separator when showMaxTime is false', (tester) async {
      await tester.pumpWidget(buildTimerText(showMaxTime: false));
      expect(find.text('/'), findsNothing);
    });
  });

  group('TimerText – recording indicator', () {
    testWidgets('shows a red dot indicator', (tester) async {
      await tester.pumpWidget(buildTimerText());
      final redDot = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == Colors.red,
      );
      expect(redDot, findsOneWidget);
    });
  });

  group('TimerText – layout', () {
    testWidgets('renders inside a Card', (tester) async {
      await tester.pumpWidget(buildTimerText());
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders content in a Row', (tester) async {
      await tester.pumpWidget(buildTimerText());
      expect(find.byType(Row), findsWidgets);
    });
  });
}

import 'package:fancy_audio_recorder/src/audio_recorder_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildWaveButton({
    required FancyAudioRecorderState state,
    VoidCallback? onPressed,
    double buttonSize = 60,
    Color? buttonColor,
    Color? waveColor,
    double waveHeight = 0,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: WaveButton(
              sampleTime: const Duration(milliseconds: 100),
              waveHeight: waveHeight,
              onPressed: onPressed ?? () {},
              state: state,
              buttonSize: buttonSize,
              buttonColor: buttonColor,
              waveColor: waveColor,
            ),
          ),
        ),
      );

  group('WaveButton – icons per state', () {
    testWidgets('shows mic icon in start state', (tester) async {
      await tester.pumpWidget(
        buildWaveButton(state: FancyAudioRecorderState.start),
      );
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.stop_rounded), findsNothing);
      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('shows stop icon in recording state', (tester) async {
      await tester.pumpWidget(
        buildWaveButton(state: FancyAudioRecorderState.recording),
      );
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('shows delete icon in recorded state', (tester) async {
      await tester.pumpWidget(
        buildWaveButton(state: FancyAudioRecorderState.recorded),
      );
      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    });
  });

  group('WaveButton – interactions', () {
    testWidgets('calls onPressed when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildWaveButton(
        state: FancyAudioRecorderState.start,
        onPressed: () => tapped = true,
      ));
      await tester.tap(find.byType(FilledButton));
      expect(tapped, isTrue);
    });

    testWidgets('onPressed can be called multiple times', (tester) async {
      int count = 0;
      await tester.pumpWidget(buildWaveButton(
        state: FancyAudioRecorderState.start,
        onPressed: () => count++,
      ));
      await tester.tap(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      expect(count, equals(3));
    });
  });

  group('WaveButton – customization', () {
    testWidgets('renders with custom buttonSize', (tester) async {
      await tester.pumpWidget(buildWaveButton(
        state: FancyAudioRecorderState.start,
        buttonSize: 80,
      ));
      expect(find.byType(WaveButton), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final style = button.style;
      expect(style, isNotNull);
    });

    testWidgets('renders with custom buttonColor without error', (tester) async {
      await tester.pumpWidget(buildWaveButton(
        state: FancyAudioRecorderState.start,
        buttonColor: Colors.green,
      ));
      expect(find.byType(WaveButton), findsOneWidget);
    });

    testWidgets('renders with custom waveColor without error', (tester) async {
      await tester.pumpWidget(buildWaveButton(
        state: FancyAudioRecorderState.start,
        waveColor: Colors.orange,
      ));
      expect(find.byType(WaveButton), findsOneWidget);
    });
  });

  group('WaveButton – wave animation', () {
    testWidgets('wave container is larger when waveHeight > 0', (tester) async {
      await tester.pumpWidget(buildWaveButton(
        state: FancyAudioRecorderState.recording,
        waveHeight: 0,
        buttonSize: 60,
      ));
      await tester.pump();

      final sizedBoxZero = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(AnimatedSize),
          matching: find.byType(SizedBox),
        ).first,
      );

      await tester.pumpWidget(buildWaveButton(
        state: FancyAudioRecorderState.recording,
        waveHeight: 1,
        buttonSize: 60,
      ));
      await tester.pump();

      final sizedBoxFull = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(AnimatedSize),
          matching: find.byType(SizedBox),
        ).first,
      );

      expect(sizedBoxFull.width!, greaterThan(sizedBoxZero.width!));
    });
  });
}

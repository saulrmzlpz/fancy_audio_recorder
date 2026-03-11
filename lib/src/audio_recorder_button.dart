import 'dart:async';
import 'dart:io';

import 'package:fancy_audio_recorder/src/audio_player.dart';
import 'package:fancy_audio_recorder/src/utils.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:record/record.dart';

class AudioRecorderButton extends StatefulWidget {
  const AudioRecorderButton({
    super.key,
    this.maxRecordTime = Duration.zero,
    this.onRecordComplete,
    this.onRecordStart,
    this.onRecordDelete,
    this.buttonSize = 60,
    this.buttonColor,
    this.waveColor,
    this.showMaxTime = true,
  });

  /// Maximum recording duration. Use [Duration.zero] for infinite recording.
  final Duration maxRecordTime;
  final ValueChanged<String?>? onRecordComplete;
  final VoidCallback? onRecordStart;
  final VoidCallback? onRecordDelete;
  final double buttonSize;
  final Color? buttonColor;
  final Color? waveColor;

  /// Whether to show the max recording time in the timer display.
  /// Always hidden when [maxRecordTime] is [Duration.zero] (infinite).
  final bool showMaxTime;

  /// Returns true if recording has no time limit.
  bool get isInfinite => maxRecordTime == Duration.zero;

  @override
  State<AudioRecorderButton> createState() => _AudioRecorderButtonState();
}

class _AudioRecorderButtonState extends State<AudioRecorderButton> {
  final record = AudioRecorder();
  final sampleTime = const Duration(milliseconds: 100);
  Duration elapsedTime = Duration.zero;
  Timer? timer;
  bool get timerIsActive => timer?.isActive ?? false;
  Uri? path;

  double waveHeight = 0;
  FancyAudioRecorderState state = FancyAudioRecorderState.start;
  final animTime = const Duration(milliseconds: 200);

  @override
  void initState() {
    record.onAmplitudeChanged(sampleTime).listen((amp) {
      if (mounted) setState(() => waveHeight = calculatedDB(amp.current));
    });

    record.onStateChanged().listen((state) {
      if (state == RecordState.stop && mounted) setState(() => waveHeight = 0);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedSize(
          duration: animTime,
          curve: Curves.easeIn,
          child: Visibility(
            visible: state == FancyAudioRecorderState.recorded,
            child: AnimatedPadding(
              duration: animTime,
              padding: state == FancyAudioRecorderState.recorded
                  ? const EdgeInsets.only(right: 80)
                  : EdgeInsets.zero,
              child: AudioSlidePlayer(
                path: path?.path ?? '',
              ),
            ),
          ),
        ),
        AnimatedAlign(
          duration: animTime,
          alignment: state != FancyAudioRecorderState.recorded
              ? Alignment.center
              : Alignment.centerRight,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: AnimatedSize(
                    duration: animTime,
                    child: Visibility(
                      visible: state == FancyAudioRecorderState.recording,
                      child: TimerText(
                          elapsedTime: elapsedTime,
                          maxRecordTime: widget.maxRecordTime,
                          paddingLeft: widget.buttonSize,
                          showMaxTime:
                              widget.showMaxTime && !widget.isInfinite),
                    ),
                  )),
              WaveButton(
                sampleTime: sampleTime,
                waveHeight: waveHeight,
                onPressed: _toggleRecord,
                state: state,
                buttonSize: widget.buttonSize,
                buttonColor: widget.buttonColor,
                waveColor: widget.waveColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleRecord() async {
    switch (state) {
      case FancyAudioRecorderState.start:
        _startRecord();
        break;
      case FancyAudioRecorderState.recording:
        _stopRecord();
        break;
      case FancyAudioRecorderState.recorded:
        _deleteRecord();
        break;
    }
  }

  void _startRecord() async {
    bool permissionDenied = !await record.hasPermission();
    if (permissionDenied) return;
    final Directory tempDir = await pp.getTemporaryDirectory();
    setState(() => state = FancyAudioRecorderState.recording);
    widget.onRecordStart?.call();
    record.start(const RecordConfig(),
        path: p.join(tempDir.path,
            'record-${DateTime.now().millisecondsSinceEpoch}.m4a'));
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => elapsedTime = Duration(seconds: timer.tick));
      if (!widget.isInfinite &&
          elapsedTime.inSeconds >= widget.maxRecordTime.inSeconds) {
        _stopRecord();
      }
    });
  }

  void _stopRecord() async {
    timer?.cancel();
    path = Uri.tryParse(await record.stop() ?? '');
    elapsedTime = Duration.zero;
    if (path != null) {
      state = FancyAudioRecorderState.recorded;
      if (widget.onRecordComplete != null) widget.onRecordComplete!(path?.path);
    } else {
      state = FancyAudioRecorderState.start;
    }

    setState(() {});
  }

  void _deleteRecord() async {
    try {
      File(path!.path).deleteSync();
    } catch (_) {}
    path = null;
    widget.onRecordDelete?.call();
    widget.onRecordComplete?.call(null);
    setState(() => state = FancyAudioRecorderState.start);
  }
}

class WaveButton extends StatelessWidget {
  const WaveButton({
    super.key,
    required this.sampleTime,
    required this.waveHeight,
    required this.onPressed,
    required this.state,
    required this.buttonSize,
    this.buttonColor,
    this.waveColor,
  });

  final Duration sampleTime;
  final double waveHeight;
  final VoidCallback onPressed;
  final FancyAudioRecorderState state;
  final double buttonSize;
  final Color? buttonColor;
  final Color? waveColor;
  final double waveFactor = 40;

  @override
  Widget build(BuildContext context) {
    final primary = buttonColor ?? Theme.of(context).colorScheme.primary;
    final wave = waveColor ?? Theme.of(context).colorScheme.primary;
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.loose,
      children: [
        Container(
          decoration: BoxDecoration(
              color: wave.withValues(alpha: 0.3), shape: BoxShape.circle),
          child: AnimatedSize(
            duration: sampleTime,
            child: SizedBox.fromSize(
              size: Size.square(buttonSize + (waveHeight * waveFactor)),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(buttonSize / 3),
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: primary,
                shape: const CircleBorder(),
                minimumSize: Size.square(buttonSize)),
            onPressed: onPressed,
            child: Icon(
              _switchIconState,
              size: 40,
            ),
          ),
        ),
      ],
    );
  }

  IconData get _switchIconState {
    switch (state) {
      case FancyAudioRecorderState.start:
        return Icons.mic;
      case FancyAudioRecorderState.recording:
        return Icons.stop_rounded;
      case FancyAudioRecorderState.recorded:
        return Icons.delete;
    }
  }
}

class TimerText extends StatelessWidget {
  const TimerText({
    super.key,
    required this.elapsedTime,
    required this.maxRecordTime,
    required this.paddingLeft,
    this.showMaxTime = true,
  });

  final Duration elapsedTime;
  final Duration maxRecordTime;
  final double paddingLeft;
  final bool showMaxTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      child: Container(
        padding: EdgeInsets.only(
          left: paddingLeft + 16,
          right: 16,
          top: 10,
          bottom: 10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatDuration(elapsedTime),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            if (showMaxTime) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '/',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
              Text(
                formatDuration(maxRecordTime),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum FancyAudioRecorderState { start, recording, recorded }

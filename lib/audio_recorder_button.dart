import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:fancy_audio_recorder/audio_player.dart';
import 'package:fancy_audio_recorder/utils.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

class AudioRecorderButton extends StatefulWidget {
  const AudioRecorderButton({super.key, required this.maxRecordDuration, this.onRecordComplete});
  final Duration maxRecordDuration;
  final ValueChanged<String?>? onRecordComplete;

  @override
  State<AudioRecorderButton> createState() => _AudioRecorderButtonState();
}

class _AudioRecorderButtonState extends State<AudioRecorderButton> {
  final sampleTime = const Duration(milliseconds: 100);
  final animTime = const Duration(milliseconds: 200);
  Record record = Record();
  double waveHeight = 0;
  Timer? timer;
  bool get timerIsActive => timer?.isActive ?? false;
  Duration elapsedTime = const Duration();
  Uri? path;
  FancyAudioRecorderState state = FancyAudioRecorderState.start;

  @override
  void initState() {
    record.onAmplitudeChanged(sampleTime).listen((amp) {
      if (mounted) setState(() => waveHeight = 40 * calculatedDB(amp.current));
    });

    record.onStateChanged().listen((state) {
      if (state == RecordState.stop && mounted) setState(() => waveHeight = 0);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        alignment: state == FancyAudioRecorderState.recorded || state == FancyAudioRecorderState.start ? Alignment.centerRight : Alignment.centerLeft,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeIn,
            child: state == FancyAudioRecorderState.recorded
                ? Padding(
                    padding: const EdgeInsets.only(right: 60),
                    child: AudioSlidePlayer(
                      path: path!.path,
                    ),
                  )
                : const SizedBox(),
          ),
          Card(
            margin: const EdgeInsets.only(left: 20),
            clipBehavior: Clip.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding:
                  state == FancyAudioRecorderState.recording ? const EdgeInsets.fromLTRB(60, 16, 16, 16) : const EdgeInsets.symmetric(vertical: 16),
              child: Text(timerIsActive ? '${formatDuration(elapsedTime)} - ${formatDuration(widget.maxRecordDuration)}' : ''),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            fit: StackFit.loose,
            children: [
              AnimatedContainer(
                duration: sampleTime,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), shape: BoxShape.circle),
                height: 60 + waveHeight,
                width: 60 + waveHeight,
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(shape: const CircleBorder(), minimumSize: const Size(0, 60)),
                onPressed: _toggleRecord,
                child: Icon(
                  _switchIconState(),
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
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

  IconData _switchIconState() {
    switch (state) {
      case FancyAudioRecorderState.start:
        return Icons.mic;
      case FancyAudioRecorderState.recording:
        return Icons.stop_rounded;
      case FancyAudioRecorderState.recorded:
        return Icons.delete;
    }
  }

  void _startRecord() async {
    state = FancyAudioRecorderState.recording;
    record.start();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedTime = Duration(seconds: timer.tick);
      if (elapsedTime.inSeconds >= widget.maxRecordDuration.inSeconds) {
        _stopRecord();
      }
    });
  }

  void _stopRecord() async {
    timer?.cancel();
    path = Uri.tryParse(await record.stop() ?? '');
    elapsedTime = const Duration();
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
    state = FancyAudioRecorderState.start;
    if (widget.onRecordComplete != null) widget.onRecordComplete!(null);
    setState(() {});
  }
}

enum FancyAudioRecorderState { start, recording, recorded }

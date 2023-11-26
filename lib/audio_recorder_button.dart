import 'dart:async';
import 'dart:io';

import 'package:fancy_audio_recorder/audio_player.dart';
import 'package:fancy_audio_recorder/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:record/record.dart';

class AudioRecorderButton extends StatefulWidget {
  const AudioRecorderButton(
      {super.key,
      required this.maxRecordTime,
      this.onRecordComplete,
      this.primaryColor,
      this.iconColor,
      this.recordIcon,
      this.stopIcon,
      this.deleteIcon});
  final Duration maxRecordTime;
  final ValueChanged<String?>? onRecordComplete;
  final Color? primaryColor;
  final Color? iconColor;
  final String? recordIcon;
  final String? stopIcon;
  final String? deleteIcon;

  @override
  State<AudioRecorderButton> createState() => _AudioRecorderButtonState();
}

class _AudioRecorderButtonState extends State<AudioRecorderButton> {
  final record = Record();
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
                primaryColor: widget.primaryColor,
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
                          paddingLeft: 60),
                    ),
                  )),
              WaveButton(
                sampleTime: sampleTime,
                waveHeight: waveHeight,
                onPressed: _toggleRecord,
                state: state,
                buttonSize: 60,
                buttonColor: widget.primaryColor,
                iconColor: widget.iconColor,
                recordIcon: getIconThrowPath(widget.recordIcon ?? ''),
                stopIcon: getIconThrowPath(widget.stopIcon ?? ''),
                deleteIcon: getIconThrowPath(widget.deleteIcon ?? ''),
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
    state = FancyAudioRecorderState.recording;
    record.start();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedTime = Duration(seconds: timer.tick);
      if (elapsedTime.inSeconds >= widget.maxRecordTime.inSeconds) {
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
    state = FancyAudioRecorderState.start;
    if (widget.onRecordComplete != null) widget.onRecordComplete!(null);

    setState(() {});
  }

  Widget? getIconThrowPath(String path) {
    if (path.isEmpty) return null;

    if ((path.endsWith('.png') ||
            path.endsWith('.jpg') ||
            path.endsWith('.jpeg')) &&
        path.startsWith('http')) {
      return Image.network(path);
    } else if (path.startsWith('http') && path.endsWith('.svg')) {
      return SvgPicture.network(
        path,
        width: 40,
        height: 40,
      );
    } else if (path.startsWith('assets') && path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: 40,
        height: 40,
      );
    } else if (path.startsWith('assets') &&
        (path.endsWith('.png') ||
            path.endsWith('.jpg') ||
            path.endsWith('.jpeg'))) {
      return Image.asset(path);
    }
    return null;
  }
}

class WaveButton extends StatelessWidget {
  const WaveButton(
      {Key? key,
      required this.sampleTime,
      required this.waveHeight,
      required this.onPressed,
      required this.state,
      required this.buttonSize,
      this.buttonColor,
      this.iconColor,
      this.recordIcon,
      this.stopIcon,
      this.deleteIcon})
      : super(key: key);

  final Duration sampleTime;
  final double waveHeight;
  final VoidCallback onPressed;
  final FancyAudioRecorderState state;
  final double buttonSize;
  final double waveFactor = 40;
  final Color? buttonColor;
  final Color? iconColor;
  final Widget? recordIcon;
  final Widget? stopIcon;
  final Widget? deleteIcon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.loose,
      children: [
        Container(
          decoration: BoxDecoration(
              color: buttonColor != null
                  ? buttonColor!.withOpacity(0.5)
                  : Theme.of(context).colorScheme.primary.withOpacity(0.5),
              shape: BoxShape.circle),
          child: AnimatedSize(
            duration: sampleTime,
            child: SizedBox.fromSize(
              size: Size.square(buttonSize + (waveHeight * waveFactor)),
            ),
          ),
        ),
        Padding(
            padding: EdgeInsets.all(buttonSize / 3),
            child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.square(buttonSize),
                  backgroundColor:
                      buttonColor ?? Theme.of(context).colorScheme.primary,
                ),
                onPressed: onPressed,
                child: AnimatedSwitcher(
                  duration: sampleTime,
                  child: _switchIconState,
                ))),
      ],
    );
  }

  Widget get _switchIconState {
    switch (state) {
      case FancyAudioRecorderState.start:
        return recordIcon ?? const Icon(Icons.mic_rounded, size: 40);
      case FancyAudioRecorderState.recording:
        return stopIcon ?? const Icon(Icons.stop_rounded, size: 40);
      case FancyAudioRecorderState.recorded:
        return deleteIcon ?? const Icon(Icons.delete_rounded, size: 40);
    }
  }
}

class TimerText extends StatelessWidget {
  const TimerText({
    super.key,
    required this.elapsedTime,
    required this.maxRecordTime,
    required this.paddingLeft,
  });

  final Duration elapsedTime;
  final Duration maxRecordTime;
  final double paddingLeft;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        margin: const EdgeInsets.all(16.0),
        padding: EdgeInsets.only(left: paddingLeft * 0.6),
        child: Text(
            '${formatDuration(elapsedTime)} - ${formatDuration(maxRecordTime)}'),
      ),
    );
  }
}

enum FancyAudioRecorderState { start, recording, recorded }

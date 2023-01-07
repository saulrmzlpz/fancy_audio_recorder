import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioSlidePlayer extends StatefulWidget {
  const AudioSlidePlayer({
    Key? key,
    required this.path,
  }) : super(key: key);
  final String path;

  @override
  State<AudioSlidePlayer> createState() => _AudioSlidePlayerState();
}

class _AudioSlidePlayerState extends State<AudioSlidePlayer> with SingleTickerProviderStateMixin {
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  Duration? _duration;
  Duration? _position;
  AudioPlayer player = AudioPlayer();

  String get _durationText => _duration?.toString().split('.').first ?? '';
  String get _positionText => _position?.toString().split('.').first ?? '';

  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    player.setSourceDeviceFile(widget.path).then((_) async {
      _duration = await player.getDuration();
      setState(() {});
    });

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    animation = Tween<double>(begin: 0.0, end: 1.0).animate(controller);

    _initStreams();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
            onPressed: () async {
              if (player.state == PlayerState.stopped || player.state == PlayerState.completed) {
                controller.forward();
                player.resume();
              } else {
                controller.reverse();
                player.stop();
              }
            },
            icon: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: animation,
            )),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value:
                    (_position != null && _duration != null && _position!.inMilliseconds > 0 && _position!.inMilliseconds < _duration!.inMilliseconds)
                        ? _position!.inMilliseconds / _duration!.inMilliseconds
                        : 0.0,
                onChanged: (v) {
                  final duration = _duration;
                  if (duration == null) {
                    return;
                  }
                  final position = v * duration.inMilliseconds;
                  player.seek(Duration(milliseconds: position.round()));
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(_positionText), Text(_durationText)]),
              )
            ],
          ),
        ),
      ],
    );
  }

  void _initStreams() {
    _positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      controller.reverse();
      setState(() {
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    player.dispose();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    controller.dispose();
    super.dispose();
  }
}

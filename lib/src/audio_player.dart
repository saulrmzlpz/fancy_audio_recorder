import 'dart:async';
import 'dart:developer';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';

class AudioSlidePlayer extends StatefulWidget {
  const AudioSlidePlayer({
    super.key,
    required this.path,
  });
  final String path;

  @override
  State<AudioSlidePlayer> createState() => _AudioSlidePlayerState();
}

class _AudioSlidePlayerState extends State<AudioSlidePlayer> with SingleTickerProviderStateMixin {
  StreamSubscription? _readyToPlaySubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playlistFinishedSubscription;
  StreamSubscription? _isPlayingSubscription;

  Duration? _duration;
  Duration _position = Duration.zero;
  final assetsAudioPlayer = AssetsAudioPlayer();
  bool _isPlaying = false;

  String get _durationText => _duration?.toString().split('.').first ?? '';
  String get _positionText => _position.toString().split('.').first;

  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    assetsAudioPlayer.open(Audio.file(widget.path), autoStart: false);

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
              if (!_isPlaying) {
                controller.forward();
                assetsAudioPlayer.play();
              } else {
                controller.reverse();
                assetsAudioPlayer.pause();
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
                value: (_duration != null && _position.inMilliseconds > 0) ? _position.inMilliseconds / _duration!.inMilliseconds : 0.0,
                onChanged: (v) {
                  if (_duration == null) return;
                  final position = v * _duration!.inMilliseconds;
                  assetsAudioPlayer.seek(Duration(milliseconds: position.round()));
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
    _readyToPlaySubscription = assetsAudioPlayer.onReadyToPlay.listen((audio) {
      if (audio == null) return;
      setState(() => _duration = audio.duration);
    });

    _isPlayingSubscription = assetsAudioPlayer.isPlaying.listen((playing) {
      setState(() => _isPlaying = playing);
    });

    _positionSubscription = assetsAudioPlayer.currentPosition.listen((position) {
      setState(() => _position = position);
      log(position.toString());
    });

    _playlistFinishedSubscription = assetsAudioPlayer.playlistFinished.listen((finished) {
      if (!finished) return;
      controller.reverse();
      setState(() => _position = Duration.zero);
    });

    assetsAudioPlayer.playerState.listen((event) {
      log(event.toString());
    });
  }

  @override
  void dispose() {
    assetsAudioPlayer.dispose();
    _readyToPlaySubscription?.cancel();
    _positionSubscription?.cancel();
    _playlistFinishedSubscription?.cancel();
    _isPlayingSubscription?.cancel();

    controller.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioSlidePlayer extends StatefulWidget {
  const AudioSlidePlayer({
    super.key,
    required this.path,
  });
  final String path;

  @override
  State<AudioSlidePlayer> createState() => _AudioSlidePlayerState();
}

class _AudioSlidePlayerState extends State<AudioSlidePlayer>
    with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;

  late AnimationController _animController;
  late Animation<double> _animation;

  String get _durationText => _formatDuration(_duration);
  String get _positionText => _formatDuration(_position);

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animController);

    _player.setFilePath(widget.path).then((_) {
      if (mounted) {
        setState(() => _duration = _player.duration ?? Duration.zero);
      }
    });

    _player.positionStream.listen((position) {
      if (mounted) setState(() => _position = position);
    });

    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      final playing = state.playing;
      setState(() => _isPlaying = playing);
      if (playing) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
        setState(() => _position = Duration.zero);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sliderValue = (_duration.inMilliseconds > 0 &&
            _position.inMilliseconds > 0)
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            if (_isPlaying) {
              _player.pause();
            } else {
              _player.play();
            }
          },
          icon: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: _animation,
          ),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: sliderValue,
                onChanged: (v) {
                  final position = v * _duration.inMilliseconds;
                  _player.seek(Duration(milliseconds: position.round()));
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(_positionText), Text(_durationText)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _player.dispose();
    _animController.dispose();
    super.dispose();
  }
}

import 'dart:async';

import 'package:just_audio/just_audio.dart';

enum EngineState { idle, loading, buffering, ready, completed }

class EngineStatus {
  const EngineStatus({required this.playing, required this.state, this.duration, this.buffered = Duration.zero});
  final bool playing;
  final EngineState state;
  final Duration? duration;
  final Duration buffered;
}

/// The slice of an audio player the handler needs; only [JustAudioEngine] touches just_audio.
abstract interface class AudioEngine {
  Stream<Duration> get positionStream;
  Stream<EngineStatus> get statusStream;
  Stream<Object> get errorStream;
  Duration get position;
  bool get playing;

  /// Loads [url] and returns its duration (null for live/unknown).
  Future<Duration?> load(String url, Map<String, String> headers);
  void play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> stop();
}

class JustAudioEngine implements AudioEngine {
  // The default header proxy is cleartext localhost, which Android blocks; ExoPlayer sends headers itself.
  final _player = AudioPlayer(useProxyForRequestHeaders: false);

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<EngineStatus> get statusStream => _player.playbackEventStream.map((event) => EngineStatus(
        playing: _player.playing,
        state: switch (event.processingState) {
          ProcessingState.idle => EngineState.idle,
          ProcessingState.loading => EngineState.loading,
          ProcessingState.buffering => EngineState.buffering,
          ProcessingState.ready => EngineState.ready,
          ProcessingState.completed => EngineState.completed,
        },
        duration: event.duration,
        buffered: event.bufferedPosition,
      ));

  @override
  Stream<Object> get errorStream => _player.errorStream;

  @override
  Duration get position => _player.position;

  @override
  bool get playing => _player.playing;

  @override
  Future<Duration?> load(String url, Map<String, String> headers) =>
      _player.setAudioSource(AudioSource.uri(Uri.parse(url), headers: headers));

  // Not awaited: just_audio's play() completes only when playback stops.
  @override
  void play() => unawaited(_player.play().catchError((Object _) {})); // failures arrive on errorStream

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() => _player.stop();
}

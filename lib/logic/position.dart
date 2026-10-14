const _saveEverySeconds = 5;
const _nearEndSeconds = 10;

bool shouldSavePosition(bool playing, double current, double lastSaved) {
  final moved = (current - lastSaved).abs();
  return playing ? moved >= _saveEverySeconds : moved >= 1;
}

double resumeTarget(double saved, double duration) => duration > 0 && saved > duration - _nearEndSeconds ? 0 : saved;

/// Position to keep when playback stops: a resume seek still in flight wins over the not-yet-seeked
/// current time, and a finished stream keeps its cleared position.
double? stopPosition(double? pendingSeek, double currentTime, bool ended) => ended ? null : pendingSeek ?? currentTime;

typedef ResumePoint = ({int stream, double seconds});

/// Where to resume a work: its first stream, else any later stream the user stopped in.
ResumePoint? inProgressPosition(Map<String, double> positions, int id) {
  final first = positions['$id:0'];
  if (first != null && first > 0) return (stream: 0, seconds: first);
  for (final MapEntry(:key, :value) in positions.entries) {
    final stream = key.startsWith('$id:') ? int.tryParse(key.substring('$id:'.length)) : null;
    if (stream != null && value > 0) return (stream: stream, seconds: value);
  }
  return null;
}

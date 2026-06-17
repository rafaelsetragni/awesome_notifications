import 'dart:async';

class PlaybackTimer {
  Duration _clockTic = Duration(seconds: 1);
  Duration? _totalTime;

  bool _isPlaying = false;

  Timer? _timer;
  Duration _now = Duration.zero;

  Function(Duration duration)? _onDone;
  Function(Duration duration)? _onData;

  PlaybackTimer({
    Function(Duration duration)? onDone,
    Function(Duration duration)? onData,
  })  : _onDone = onDone,
        _onData = onData;

  Duration get now => _now;
  set now(Duration duration) {
    _now = duration;
    if (_onData != null) _onData!(now);
  }

  bool get isPlaying => _isPlaying;

  void playPause(Duration totalTime) {
    if (now == Duration.zero) {
      _startNewCycle(totalTime);
      return;
    }
    if (_isPlaying) {
      _isPlaying = false;
      _timer?.cancel();
      return;
    }
    _resume();
  }

  void goTo(Duration moment) {
    if (moment == _totalTime) {
      stop();
      if (_onDone != null) _onDone!(now);
    } else {
      now = moment;
    }
  }

  void stop() {
    _isPlaying = false;

    _timer?.cancel();
    _timer = null;

    _totalTime = null;
    now = Duration.zero;
  }

  void _startNewCycle(Duration totalTime) {
    _isPlaying = false;

    _timer?.cancel();
    _timer = null;

    _totalTime = totalTime;
    now = Duration.zero;

    _resume();
  }

  void _resume() {
    _isPlaying = true;

    _timer = Timer(_clockTic, () {
      now += _clockTic;

      if (now > _totalTime!) {
        _timer!.cancel();
        now = Duration.zero;

        if (isPlaying && _onDone != null) _onDone!(now);
      } else {
        _resume();
      }
    });
  }
}

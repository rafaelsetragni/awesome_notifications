import 'dart:async';
import 'dart:math';

import 'package:awesome_notifications_example/models/media_model.dart';
import 'package:awesome_notifications_example/utils/playback_timer.dart';

enum MediaLifeCycle {
  Stopped,
  Paused,
  Playing,
}

class MediaPlayerCentral {

  static final PlaybackTimer _timer = PlaybackTimer(
      onDone: (Duration duration){
        if(hasNextMedia) {
          nextMedia();
        } else {
          stop();
        }
      },
      onData: (Duration duration){
        _mediaProgress.add(_timer.now);
      }
  );

  static String getCloseCaption(Duration duration){
    if( currentMedia?.closeCaption.isEmpty ?? true ) return '';

    for(CloseCaptionElement cc in currentMedia!.closeCaption){
      if(cc.start <= duration && cc.end >= duration) return cc.subtitle;
    }

    return '';
  }

  static Duration replayTolerance = Duration(seconds: 4);

  static int _index = 0;
  static MediaLifeCycle _lifeCycle = MediaLifeCycle.Stopped;
  static List<MediaModel> _playlist = [];

  // ignore: close_sinks
  static StreamController<MediaModel> _mediaBroadcaster =
      StreamController<MediaModel>.broadcast();
  static StreamController<Duration> _mediaProgress =
      StreamController<Duration>.broadcast();

  Stream<MediaModel> get mediaBroadcaster {
    return _mediaBroadcaster.stream;
  }

  Stream<Duration> get mediaProgress {
    return _mediaProgress.stream;
  }

  static int get index => _index;
  static set index(int index) {
    _index = min(_playlist.length, max(0, index));
  }

  static Duration get currentDuration => _timer.now;

  static bool get isPlaying {
    return _lifeCycle == MediaLifeCycle.Playing;
  }

  static MediaLifeCycle get mediaLifeCycle => _lifeCycle;

  static MediaModel? get currentMedia {
    return _playlist.length == 0 ? null : _playlist[_index];
  }

  static bool get hasAnyMedia => _playlist.isNotEmpty;
  static bool get hasNextMedia => hasAnyMedia && index < _playlist.length - 1;
  static bool get hasPreviousMedia => hasAnyMedia && index > 0;

  static Stream get mediaStream {
    if (_mediaBroadcaster.isClosed)
      _mediaBroadcaster = StreamController<MediaModel>.broadcast();
    return _mediaBroadcaster.stream;
  }
  static Stream get progressStream {
    if (_mediaProgress.isClosed)
      _mediaProgress = StreamController<Duration>.broadcast();
    return _mediaProgress.stream;
  }
  static StreamSink get mediaSink => _mediaBroadcaster.sink;
  static StreamSink get progressSink => _mediaProgress.sink;

  static void _broadcastChanges(){
    _mediaBroadcaster.sink.add(
        currentMedia!
    );
    _mediaProgress.sink.add(
        _timer.now
    );
  }

  static void add(MediaModel newMedia) {
    if (_playlist.contains(newMedia)) {
    } else {
      _playlist.add(newMedia);
    }
  }

  static void addAll(List<MediaModel> newMedias) {
    _playlist..addAll(newMedias);
  }

  static void remove(MediaModel oldMedia) {
    if (currentMedia == oldMedia) {
      _timer.stop();
      _playlist.remove(oldMedia);
      _broadcastChanges();
    } else {
      _playlist.remove(oldMedia);
    }
  }

  static void clear() {
    _playlist.clear();
    stop();
  }

  static void playPause() {
    switch (_lifeCycle) {
      case MediaLifeCycle.Stopped:
      case MediaLifeCycle.Paused:
        _lifeCycle = MediaLifeCycle.Playing;
        _timer.playPause(currentMedia!.trackSize);
        _broadcastChanges();
        break;

      case MediaLifeCycle.Playing:
        _lifeCycle = MediaLifeCycle.Paused;
        _timer.playPause(currentMedia!.trackSize);
        _broadcastChanges();
        break;
    }
  }

  static void stop() {
    _lifeCycle = MediaLifeCycle.Stopped;
    _timer.stop();
    _broadcastChanges();
  }

  static void goTo(Duration moment) {
    _timer.goTo(moment);
    _lifeCycle = _timer.isPlaying ? MediaLifeCycle.Playing : _lifeCycle;
    _broadcastChanges();
  }

  static void nextMedia() {
    if (hasNextMedia) {
      _index++;
    }

    switch (_lifeCycle) {
      case MediaLifeCycle.Stopped:
        _timer.stop();
        _lifeCycle = MediaLifeCycle.Stopped;
        break;

      case MediaLifeCycle.Paused:
        _timer.stop();
        _lifeCycle = MediaLifeCycle.Paused;
        break;

      case MediaLifeCycle.Playing:
        _timer.stop();
        _timer.playPause(currentMedia!.trackSize);
        _lifeCycle = MediaLifeCycle.Playing;
        break;
    }
    _broadcastChanges();
  }

  static void previousMedia() {
    if (hasPreviousMedia) {
      if (_timer.now < replayTolerance) {
        _index--;
      }
    }

    switch (_lifeCycle) {
      case MediaLifeCycle.Playing:
        _timer.stop();
        _timer.playPause(currentMedia!.trackSize);
        _lifeCycle = MediaLifeCycle.Playing;
        break;

      case MediaLifeCycle.Paused:
        _timer.stop();
        _lifeCycle = MediaLifeCycle.Paused;
        break;

      case MediaLifeCycle.Stopped:
        break;
    }

    _broadcastChanges();
  }

  dispose() {
    _mediaBroadcaster.sink.close();
    _mediaProgress.sink.close();
  }
}

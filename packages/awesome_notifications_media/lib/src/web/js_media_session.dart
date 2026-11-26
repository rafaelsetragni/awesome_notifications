import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'web_media_controller.dart';

@JS('navigator')
external JSObject get _navigator;

extension type _MediaSession._(JSObject _) implements JSObject {
  external set metadata(JSObject? value);
  external set playbackState(String value);
  external void setActionHandler(String action, JSFunction? handler);
  external void setPositionState([JSObject state]);
}

@JS('MediaMetadata')
extension type _MediaMetadata._(JSObject _) implements JSObject {
  external factory _MediaMetadata(JSObject init);
}

/// [MediaSessionApi] over `navigator.mediaSession`.
class JsMediaSession implements MediaSessionApi {
  _MediaSession? get _session => _navigator.has('mediaSession')
      ? _navigator.getProperty<JSObject>('mediaSession'.toJS) as _MediaSession
      : null;

  @override
  bool get available => _session != null;

  @override
  void setMetadata({required String title, String? artist, String? album, String? artworkUrl}) {
    _session?.metadata = _MediaMetadata({
      'title': title,
      'artist': artist ?? '',
      'album': album ?? '',
      'artwork': [
        if (artworkUrl != null) {'src': artworkUrl},
      ],
    }.jsify() as JSObject);
  }

  @override
  void clearMetadata() => _session?.metadata = null;

  @override
  void setPlaybackState(String state) => _session?.playbackState = state;

  @override
  void setPositionState({required double duration, required double playbackRate, required double position}) {
    try {
      _session?.setPositionState({
        'duration': duration,
        'playbackRate': playbackRate,
        'position': position,
      }.jsify() as JSObject);
    } catch (_) {
      // Not supported by this browser.
    }
  }

  @override
  void clearPositionState() {
    try {
      _session?.setPositionState();
    } catch (_) {
      // Not supported by this browser.
    }
  }

  @override
  void setActionHandler(String action, void Function(double? seekTime)? handler) {
    try {
      _session?.setActionHandler(
          action,
          handler == null
              ? null
              : ((JSObject? details) {
                  final seekTime = details?.getProperty<JSAny?>('seekTime'.toJS);
                  handler(seekTime.isA<JSNumber>() ? (seekTime as JSNumber).toDartDouble : null);
                }).toJS);
    } catch (_) {
      // This browser doesn't support the action.
    }
  }
}

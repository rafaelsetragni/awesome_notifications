import 'dart:async';

import 'package:flutter/services.dart';

import '../../awesome_notifications_media.dart';
import '../media_keys.dart';

/// The browser's media session (`navigator.mediaSession`), behind an
/// interface so the logic is testable without a browser.
abstract class MediaSessionApi {
  /// The browser has a media session.
  bool get available;

  void setMetadata({required String title, String? artist, String? album, String? artworkUrl});
  void clearMetadata();

  /// 'playing', 'paused' or 'none'.
  void setPlaybackState(String state);

  /// Seconds.
  void setPositionState({required double duration, required double playbackRate, required double position});
  void clearPositionState();

  /// [action] is a MediaSessionAction ('play', 'seekto'…); the handler gets
  /// the `seekTime` (seconds) of a `seekto`. A null handler removes it.
  void setActionHandler(String action, void Function(double? seekTime)? handler);
}

/// Emits the core's action event of a model.
typedef WebActionDispatcher = Future<void> Function(
  Map<String, dynamic> model, {
  required String buttonKey,
  String? input,
  Map<String, dynamic>? button,
});

/// Every MediaSessionAction the package uses.
const webMediaActions = [
  'play',
  'pause',
  'stop',
  'nexttrack',
  'previoustrack',
  'seekforward',
  'seekbackward',
  'seekto',
];

/// The control behind each browser action, from a model's `controls`.
/// fastForward / rewind take seekforward / seekbackward only when the skip
/// controls are absent.
Map<String, MediaControl> webActionsOf(Iterable<MediaControl> controls) {
  final set = controls.toSet();
  MediaControl? first(List<MediaControl> options) =>
      options.where(set.contains).firstOrNull;
  final map = <String, MediaControl?>{
    'play': first([MediaControl.play]),
    'pause': first([MediaControl.pause]),
    'stop': first([MediaControl.stop]),
    'nexttrack': first([MediaControl.skipNext]),
    'previoustrack': first([MediaControl.skipPrevious]),
    'seekforward': first([MediaControl.skipForward, MediaControl.fastForward]),
    'seekbackward': first([MediaControl.skipBackward, MediaControl.rewind]),
    'seekto': first([MediaControl.seekTo]),
  };
  return {
    for (final e in map.entries)
      if (e.value != null) e.key: e.value!,
  };
}

/// The browser playback state of a NotificationPlayState name.
String webPlaybackStateOf(String? state) {
  switch (state) {
    case 'playing':
    case 'buffering':
    case 'connecting':
    case 'forwarding':
    case 'rewinding':
    case 'previous':
    case 'next':
    case 'skippingToQueueItem':
      return 'playing';
    case 'paused':
      return 'paused';
    default:
      return 'none';
  }
}

/// The URL the browser loads an artwork from: http(s) as is, asset:// through
/// [assetUrl]; null for sources a page can't load (file://, resource://).
String? webArtworkUrlOf(String? artwork, String Function(String key) assetUrl) {
  if (artwork == null || artwork.isEmpty) return null;
  if (artwork.startsWith('http://') || artwork.startsWith('https://')) return artwork;
  const asset = 'asset://';
  if (artwork.startsWith(asset)) return assetUrl(artwork.substring(asset.length));
  return null;
}

/// The web media layer: builds the page's media session from the models the
/// package owns, answers the media methods and delivers the commands.
class WebMediaController implements MediaPlatformBridge {
  WebMediaController(this.api, {required this.dispatchAction, required this.assetUrl});

  final MediaSessionApi api;
  final WebActionDispatcher dispatchAction;
  final String Function(String key) assetUrl;

  final _commands = StreamController<Object?>.broadcast();

  /// sessionId → the last model map of that session.
  final Map<String, Map<String, dynamic>> _sessions = {};

  /// The session on the page's media session (a page has only one).
  String? activeSessionId;

  @override
  Stream<Object?> get commandEvents => _commands.stream;

  static PlatformException _invalid(String message, String detail) => PlatformException(
      code: 'INVALID_ARGUMENTS', message: message, details: detail);

  /// The core's web builder: null when the model is not a media one.
  Future<bool?> build(Map<String, dynamic> model) async {
    final content = model['content'];
    final isMediaLayout = content is Map && content['notificationLayout'] == 'MediaPlayer';
    final rawMedia = model[MediaKeys.media];
    if (rawMedia == null && !isMediaLayout) return null;
    final source = content is Map ? content['createdSource'] : null;
    if (source is String && source.toLowerCase() == 'firebase') {
      throw _invalid('Media notifications can\'t come from a push',
          'arguments.invalid.notificationMedia.push');
    }
    if (model['schedule'] != null) {
      throw _invalid('Media notifications can\'t be scheduled',
          'arguments.invalid.notificationMedia.schedule');
    }
    if (rawMedia == null) {
      throw _invalid('A MediaPlayer notification needs a NotificationMedia',
          'arguments.invalid.notificationMedia');
    }
    if (!isMediaLayout) {
      throw _invalid('NotificationMedia needs the MediaPlayer layout',
          'arguments.invalid.notificationMedia.layout');
    }
    final media = Map<String, dynamic>.from(rawMedia as Map);
    final sessionId = media[MediaKeys.sessionId];
    final title = media[MediaKeys.title];
    if (sessionId is! String || sessionId.isEmpty || title is! String) {
      throw _invalid('The media needs a sessionId and a title', 'arguments.invalid.notificationMedia');
    }

    final newContent = Map<String, dynamic>.from(content);
    if ((newContent['title'] as String?)?.isNotEmpty != true) newContent['title'] = title;
    final artist = media[MediaKeys.artist] as String?;
    if ((newContent['body'] as String?)?.isNotEmpty != true && artist != null) {
      newContent['body'] = artist;
    }
    newContent['payload'] = <String, String?>{
      ...?(newContent['payload'] as Map?)?.cast<String, String?>(),
      MediaKeys.payloadSessionId: sessionId,
    };
    // The core reports the updated model in the created / displayed events.
    model['content'] = newContent;
    model[MediaKeys.media] = media;
    _sessions[sessionId] = {...model};
    activeSessionId = sessionId;

    if (!api.available) return false;
    _apply(sessionId, media);
    return true;
  }

  /// The core's removal hook: a cancel / dismiss of a session's notification
  /// ([removes] tells it from its model) ends the session, as `mediaStop`
  /// does, whatever its state.
  void onRemoved(bool Function(Map<String, dynamic> model) removes) {
    final removed = [
      for (final e in _sessions.entries)
        if (removes(e.value)) e.key,
    ];
    removed.forEach(_stop);
  }

  void _apply(String sessionId, Map<String, dynamic> media) {
    api.setMetadata(
      title: media[MediaKeys.title] as String,
      artist: media[MediaKeys.artist] as String?,
      album: media[MediaKeys.album] as String?,
      artworkUrl: webArtworkUrlOf(media[MediaKeys.artwork] as String?, assetUrl),
    );
    api.setPlaybackState(webPlaybackStateOf(media[MediaKeys.state] as String?));
    _applyPosition(media);

    final controls = [
      for (final name in (media[MediaKeys.controls] as List? ?? const []))
        ...MediaControl.values.where((c) => c.name == name),
    ];
    final actions = webActionsOf(controls);
    for (final action in webMediaActions) {
      final control = actions[action];
      api.setActionHandler(
          action,
          control == null
              ? null
              : (seekTime) => _onCommand(sessionId, control, seekTime));
    }
  }

  void _applyPosition(Map<String, dynamic> media) {
    final duration = media[MediaKeys.duration] as int?;
    if (duration == null || duration <= 0) {
      api.clearPositionState();
      return;
    }
    final position = ((media[MediaKeys.position] as int?) ?? 0).clamp(0, duration);
    final speed = (media[MediaKeys.playbackSpeed] as num?)?.toDouble() ?? 0;
    api.setPositionState(
      duration: duration / 1000,
      // The browser rejects a zero rate: a paused state already stops it.
      playbackRate: speed > 0 ? speed : 1.0,
      position: position / 1000,
    );
  }

  Future<void> _onCommand(String sessionId, MediaControl control, double? seekTime) async {
    final model = _sessions[sessionId];
    if (model == null) return;
    final media = model[MediaKeys.media] as Map<String, dynamic>;
    final position = control == MediaControl.seekTo && seekTime != null
        ? (seekTime * 1000).round()
        : null;
    final target = media[MediaKeys.commandTarget] as String? ?? MediaCommandTarget.actionEvent.name;
    if (target == MediaCommandTarget.stream.name || target == MediaCommandTarget.both.name) {
      _commands.add({
        MediaKeys.control: control.name,
        MediaKeys.sessionId: sessionId,
        if (position != null) MediaKeys.position: position,
      });
    }
    if (target == MediaCommandTarget.actionEvent.name || target == MediaCommandTarget.both.name) {
      await dispatchAction(
        model,
        buttonKey: control.key,
        input: position?.toString(),
        button: {'key': control.key, 'actionType': 'SilentAction', 'autoDismissible': false},
      );
    }
  }

  @override
  Future<Object?> invokeMethod(String method, [Object? arguments]) async {
    switch (method) {
      case MediaKeys.methodStop:
        _stop(arguments as String);
        return null;
      case MediaKeys.methodUpdatePosition:
        final map = (arguments as Map).cast<String, dynamic>();
        _updatePosition(map[MediaKeys.sessionId] as String, map[MediaKeys.position] as int);
        return null;
      case MediaKeys.methodCapabilities:
        final on = api.available;
        return {'seekBar': on, 'artwork': on, 'customButtons': false, 'lockScreen': false};
    }
    throw MissingPluginException('No web implementation for $method');
  }

  void _stop(String sessionId) {
    _sessions.remove(sessionId);
    if (activeSessionId != sessionId) return;
    activeSessionId = null;
    if (!api.available) return;
    api.clearMetadata();
    api.setPlaybackState('none');
    api.clearPositionState();
    for (final action in webMediaActions) {
      api.setActionHandler(action, null);
    }
  }

  void _updatePosition(String sessionId, int position) {
    final model = _sessions[sessionId];
    if (model == null) return;
    final media = model[MediaKeys.media] as Map<String, dynamic>;
    media[MediaKeys.position] = position;
    if (activeSessionId == sessionId && api.available) _applyPosition(media);
  }
}

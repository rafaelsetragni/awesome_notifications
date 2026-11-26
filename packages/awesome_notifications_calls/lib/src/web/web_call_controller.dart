import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/services.dart';

import '../../awesome_notifications_calls.dart';
import '../call_keys.dart';

/// A button of a call notification: the call action it sends and its text.
class WebCallButton {
  final CallAction action;
  final String title;

  const WebCallButton(this.action, this.title);

  @override
  bool operator ==(Object other) =>
      other is WebCallButton && other.action == action && other.title == title;

  @override
  int get hashCode => Object.hash(action, title);

  @override
  String toString() => 'WebCallButton(${action.name}, $title)';
}

/// The browser's notifications (`Notification`), behind an interface so the
/// logic is testable without a browser.
///
/// What a page can do on the web, without a service worker (the core has
/// none yet):
/// * it shows a page notification (`new Notification(…)`), replaced in place
///   when shown again with the same tag, kept on screen until the user acts
///   on it with `requireInteraction` (Chrome and Edge; Firefox and Safari
///   ignore it);
/// * a click on the notification's body reaches the page, which focuses
///   itself;
/// * it can't have buttons: the browser only gives `actions` to the
///   persistent notifications of a service worker
///   (`ServiceWorkerRegistration.showNotification`), whose clicks
///   (`notificationclick`) reach the worker, not the page. [buttons] are
///   therefore not shown by the page implementation; the logic behind them
///   is complete, so a service worker of the core only has to forward the
///   clicked action to `onClick`.
/// * nothing reaches a closed page: no ringing with the page closed (no
///   push), no lock screen, no ringing sound of its own (the system's
///   notification sound only).
abstract class CallNotificationApi {
  /// The browser shows notifications and the user allowed them.
  bool get available;

  /// Shows (or replaces, same [tag]) a notification. [onClick] receives the
  /// clicked button's action, or null for a click on the body.
  void show(
    String tag, {
    required String title,
    required String body,
    String? icon,
    required bool requireInteraction,
    required List<WebCallButton> buttons,
    required void Function(CallAction? action) onClick,
  });

  /// Closes the notification of [tag], when shown.
  void close(String tag);

  /// Brings the page to the front.
  void focusPage();
}

/// Emits the core's action event of a model.
typedef WebActionDispatcher = Future<void> Function(
  Map<String, dynamic> model, {
  required String buttonKey,
  String? input,
  Map<String, dynamic>? button,
});

/// The core's `createNotificationFromJsonData` (the missed call notification
/// goes through the core, so its created / displayed events fire).
typedef WebNotificationCreator = Future<bool> Function(Map<String, dynamic> model);

typedef WebTimerFactory = Timer Function(Duration duration, void Function() callback);

/// Top-level key of the missed call notifications the package creates
/// through the core, so its builder recognizes them. Web only, internal.
const webMissedCallKey = 'awn.call.missedNotification';

/// The stable id of a call's missed notification: Java's `String.hashCode`
/// of `"missed:" + callId`, positive.
int missedNotificationIdOf(String callId) {
  var hash = 0;
  for (final unit in 'missed:$callId'.codeUnits) {
    hash = (31 * hash + unit) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

/// The URL the browser loads an image from: http(s) as is, asset:// through
/// [assetUrl]; null for sources a page can't load (file://, resource://).
String? webImageUrlOf(String? image, String Function(String key) assetUrl) {
  if (image == null || image.isEmpty) return null;
  if (image.startsWith('http://') || image.startsWith('https://')) return image;
  const asset = 'asset://';
  if (image.startsWith(asset)) return assetUrl(image.substring(asset.length));
  return null;
}

PlatformException _invalid(String message, [String detail = 'arguments.invalid.notificationCall']) =>
    PlatformException(code: 'INVALID_ARGUMENTS', message: message, details: detail);

/// Validates a `call` block as `NotificationCall.validate` does (a model may
/// come from JSON without passing through Dart's model) and returns it with
/// its defaults filled in. Throws a [PlatformException] when it's invalid.
Map<String, dynamic> parseWebCall(Object? raw) {
  if (raw is! Map) throw _invalid('The call block must be a map');
  final call = Map<String, dynamic>.from(raw);

  final callId = call[CallKeys.callId];
  if (callId is! String || callId.trim().isEmpty) throw _invalid('The call needs a non-empty callId');

  final rawCaller = call[CallKeys.caller];
  final caller = rawCaller is Map ? NotificationPerson.fromMap(rawCaller.cast<String, dynamic>()) : null;
  if (caller == null) throw _invalid('The call needs a caller with a key and a name');
  try {
    caller.validate('caller');
  } on AwesomeNotificationsException catch (e) {
    throw _invalid(e.message);
  }

  final handle = call[CallKeys.handle];
  if (handle != null && (handle is! String || handle.trim().isEmpty)) {
    throw _invalid('The call handle can\'t be empty (leave it out to use the caller\'s key)');
  }
  final groupName = call[CallKeys.groupName];
  if (groupName != null && (groupName is! String || groupName.trim().isEmpty)) {
    throw _invalid('The call groupName can\'t be empty');
  }
  final video = call[CallKeys.video] ?? false;
  if (video is! bool) throw _invalid('The call video must be a bool');

  final state = CallState.values.where((s) => s.name == call[CallKeys.state]).firstOrNull;
  if (state == null) throw _invalid('Unknown call state: ${call[CallKeys.state]}');

  final startedAt = call[CallKeys.startedAt];
  if (startedAt != null && startedAt is! num) throw _invalid('The call startedAt must be milliseconds');

  final ringTimeout = call[CallKeys.ringTimeout] ?? 60000;
  if (ringTimeout is! num || ringTimeout <= 0) throw _invalid('The ring timeout must be positive');

  final missedNotification = call[CallKeys.missedNotification] ?? true;
  if (missedNotification is! bool) throw _invalid('The call missedNotification must be a bool');

  final rawControls = call[CallKeys.controls];
  final List<String> controls;
  if (rawControls == null) {
    controls = [for (final c in CallControl.values) c.name];
  } else if (rawControls is List) {
    controls = [];
    for (final name in rawControls) {
      if (!CallControl.values.any((c) => c.name == name)) throw _invalid('Unknown call control: $name');
      controls.add(name as String);
    }
  } else {
    throw _invalid('The call controls must be a list');
  }
  if (state == CallState.incoming &&
      !controls.contains(CallControl.accept.name) &&
      !controls.contains(CallControl.decline.name)) {
    throw _invalid('An incoming call needs the accept or the decline control');
  }

  final target = call[CallKeys.commandTarget] ?? CallCommandTarget.actionEvent.name;
  if (!CallCommandTarget.values.any((t) => t.name == target)) {
    throw _invalid('Unknown call commandTarget: $target');
  }

  final rawTexts = call[CallKeys.texts];
  if (rawTexts != null && rawTexts is! Map) throw _invalid('The call texts must be a map');
  final texts = <String, dynamic>{
    ...const CallTexts().toMap(),
    for (final e in ((rawTexts as Map?) ?? const {}).entries)
      if (e.value is String) e.key as String: e.value,
  };

  return {
    ...call,
    CallKeys.callId: callId,
    CallKeys.caller: caller.toMap(),
    CallKeys.video: video,
    CallKeys.state: state.name,
    if (startedAt != null) CallKeys.startedAt: (startedAt as num).toInt(),
    CallKeys.ringTimeout: ringTimeout.toInt(),
    CallKeys.missedNotification: missedNotification,
    CallKeys.controls: controls,
    CallKeys.commandTarget: target,
    CallKeys.texts: texts,
  };
}

class _Call {
  _Call(this.model, this.call, this.appTitle, this.appBody);

  /// The model as reported in the events (content with the callId payload).
  Map<String, dynamic> model;

  /// The validated `call` block, kept up to date with the state.
  Map<String, dynamic> call;

  /// The app's own title / body (null: the package's).
  String? appTitle, appBody;

  Timer? ringTimer;

  String get callId => call[CallKeys.callId] as String;
  CallState get state => CallState.values.byName(call[CallKeys.state] as String);
  Map<String, dynamic> get texts => call[CallKeys.texts] as Map<String, dynamic>;
  Map<String, dynamic> get caller => call[CallKeys.caller] as Map<String, dynamic>;
  bool get video => call[CallKeys.video] == true;
  String get name => (call[CallKeys.groupName] as String?) ?? caller[NotificationPerson.keyName] as String;
  bool has(CallControl control) => (call[CallKeys.controls] as List).contains(control.name);
}

/// The web call layer: shows the call notifications from the models the
/// package owns, runs the ring timer and the call's states, answers the call
/// methods and delivers the commands.
class WebCallController implements CallsPlatformBridge {
  WebCallController(
    this.api, {
    required this.dispatchAction,
    required this.createNotification,
    required this.assetUrl,
    WebTimerFactory? timer,
    DateTime Function()? now,
  })  : _timer = timer ?? Timer.new,
        _now = now ?? DateTime.now;

  final CallNotificationApi api;
  final WebActionDispatcher dispatchAction;
  final WebNotificationCreator createNotification;
  final String Function(String key) assetUrl;
  final WebTimerFactory _timer;
  final DateTime Function() _now;

  final _events = StreamController<Object?>.broadcast();

  /// callId → the call the page shows.
  final Map<String, _Call> _calls = {};

  /// Notification id → the missed call notifications shown.
  final Map<int, Map<String, dynamic>> _missed = {};

  @override
  Stream<Object?> get events => _events.stream;

  static String _tagOf(String callId) => '${CallKeys.commandPrefix}$callId';
  static String _missedTagOf(int id) => '${CallKeys.commandPrefix}missed.$id';

  /// The core's web builder: null when the model is not a call one.
  Future<bool?> build(Map<String, dynamic> model) async {
    if (model[webMissedCallKey] == true) return _showMissed(model);
    final rawCall = model[CallKeys.call];
    if (rawCall == null) return null;
    if (model['schedule'] != null) {
      throw _invalid('Call notifications can\'t be scheduled',
          'arguments.invalid.notificationCall.schedule');
    }
    final call = parseWebCall(rawCall);
    final callId = call[CallKeys.callId] as String;
    final content = Map<String, dynamic>.from((model[NOTIFICATION_CONTENT] as Map?) ?? const {});
    content[NOTIFICATION_PAYLOAD] = <String, String?>{
      ...?(content[NOTIFICATION_PAYLOAD] as Map?)?.cast<String, String?>(),
      CallKeys.payloadCallId: callId,
    };
    String? own(Object? text) => text is String && text.isNotEmpty ? text : null;
    final appTitle = own(content[NOTIFICATION_TITLE]);
    final appBody = own(content[NOTIFICATION_BODY]);

    final previous = _calls[callId];
    final entry = _Call(model, call, appTitle, appBody);
    final state = entry.state;
    if (state == CallState.ongoing || state == CallState.held) {
      // Keeps the timer's base of a call answered on the page.
      call[CallKeys.startedAt] ??= previous?.call[CallKeys.startedAt];
    }
    content[NOTIFICATION_TITLE] = appTitle ?? entry.name;
    content[NOTIFICATION_BODY] = appBody ?? _textOf(entry);
    // The core reports the updated model in the created / displayed events.
    model[NOTIFICATION_CONTENT] = content;
    model[CallKeys.call] = call;

    switch (state) {
      case CallState.ended:
        _end(callId);
        return true;
      case CallState.missed:
        _end(callId);
        if (call[CallKeys.missedNotification] == true) await _createMissed(entry);
        return true;
      case CallState.incoming:
        // A call already ringing keeps its timer: an update doesn't ring longer.
        final ringing = previous?.state == CallState.incoming ? previous!.ringTimer : null;
        if (ringing == null) previous?.ringTimer?.cancel();
        entry.ringTimer = ringing ??
            _timer(Duration(milliseconds: call[CallKeys.ringTimeout] as int), () => _onTimeout(callId));
      case CallState.outgoing:
      case CallState.ongoing:
      case CallState.held:
        previous?.ringTimer?.cancel();
    }
    _calls[callId] = entry;
    return _show(entry);
  }

  String _textOf(_Call call) {
    final texts = call.texts;
    switch (call.state) {
      case CallState.incoming:
        return texts[call.video ? CallKeys.textIncomingVideo : CallKeys.textIncoming] as String;
      case CallState.outgoing:
        return texts[CallKeys.textOutgoing] as String;
      case CallState.missed:
        return texts[call.video ? CallKeys.textMissedVideo : CallKeys.textMissed] as String;
      case CallState.held:
        return texts[CallKeys.textHeld] as String;
      case CallState.ongoing:
      case CallState.ended:
        return texts[CallKeys.textOngoing] as String;
    }
  }

  List<WebCallButton> _buttonsOf(_Call call) {
    final texts = call.texts;
    final pairs = call.state == CallState.incoming
        ? [(CallControl.accept, CallAction.accept, CallKeys.textAccept),
           (CallControl.decline, CallAction.decline, CallKeys.textDecline)]
        : [(CallControl.hangUp, CallAction.hangUp, CallKeys.textHangUp)];
    return [
      for (final (control, action, text) in pairs)
        if (call.has(control)) WebCallButton(action, texts[text] as String),
    ];
  }

  bool _show(_Call call) {
    if (!api.available) return false;
    final callId = call.callId;
    api.show(
      _tagOf(callId),
      title: call.appTitle ?? call.name,
      body: call.appBody ?? _textOf(call),
      icon: webImageUrlOf(call.caller[NotificationPerson.keyAvatar] as String?, assetUrl),
      requireInteraction: true,
      buttons: _buttonsOf(call),
      onClick: (action) => _onClick(callId, action),
    );
    return true;
  }

  Future<void> _onClick(String callId, CallAction? action) async {
    final call = _calls[callId];
    if (call == null) return;
    if (action != null) return _onCommand(callId, action);
    // A click on the body opens the app, as a tap on any notification does:
    // the action event without a button (not a call command).
    api.focusPage();
    await dispatchAction(call.model,
        buttonKey: '', button: {NOTIFICATION_ACTION_TYPE: ActionType.Default.name});
  }

  /// A command of the user or the system: applied to the call first, then
  /// delivered.
  Future<void> _onCommand(String callId, CallAction action) async {
    final call = _calls[callId];
    if (call == null) return;
    switch (action) {
      case CallAction.accept:
        if (call.state != CallState.incoming) return;
        call.ringTimer?.cancel();
        call.ringTimer = null;
        call.call = {
          ...call.call,
          CallKeys.state: CallState.ongoing.name,
          CallKeys.startedAt: call.call[CallKeys.startedAt] ?? _now().toUtc().millisecondsSinceEpoch,
        };
        _show(call);
      case CallAction.decline:
      case CallAction.hangUp:
        _end(callId);
      case CallAction.timeout:
        _end(callId);
        if (call.call[CallKeys.missedNotification] == true) await _createMissed(call);
      default:
        // No mute / hold on the web.
        return;
    }
    await _deliver(call, action);
  }

  Future<void> _deliver(_Call call, CallAction action) async {
    final target = call.call[CallKeys.commandTarget] as String;
    final toStream = target == CallCommandTarget.stream.name || target == CallCommandTarget.both.name;
    final toAction = target == CallCommandTarget.actionEvent.name || target == CallCommandTarget.both.name;
    if (toStream) {
      _events.add({
        CallKeys.kind: CallKeys.kindCommand,
        CallKeys.action: action.name,
        CallKeys.callId: call.callId,
      });
    }
    if (toAction) {
      await dispatchAction(call.model, buttonKey: action.key, button: {
        'key': action.key,
        NOTIFICATION_ACTION_TYPE:
            action == CallAction.accept ? ActionType.Default.name : ActionType.SilentAction.name,
        'autoDismissible': false,
      });
    }
  }

  void _onTimeout(String callId) {
    final call = _calls[callId];
    if (call == null || call.state != CallState.incoming) return;
    call.ringTimer = null;
    _onCommand(callId, CallAction.timeout);
  }

  /// Ends the call on the page: its notification and timer. No command.
  _Call? _end(String callId) {
    final call = _calls.remove(callId);
    call?.ringTimer?.cancel();
    call?.ringTimer = null;
    api.close(_tagOf(callId));
    return call;
  }

  /// A regular notification on the call's channel, through the core.
  Future<void> _createMissed(_Call call) async {
    final content = (call.model[NOTIFICATION_CONTENT] as Map?) ?? const {};
    final callId = call.callId;
    await createNotification({
      NOTIFICATION_CONTENT: {
        NOTIFICATION_ID: missedNotificationIdOf(callId),
        NOTIFICATION_CHANNEL_KEY: content[NOTIFICATION_CHANNEL_KEY],
        NOTIFICATION_TITLE: call.name,
        NOTIFICATION_BODY:
            call.texts[call.video ? CallKeys.textMissedVideo : CallKeys.textMissed],
        if (call.caller[NotificationPerson.keyAvatar] case final String avatar)
          NOTIFICATION_LARGE_ICON: avatar,
        NOTIFICATION_PAYLOAD: {CallKeys.payloadCallId: callId},
      },
      webMissedCallKey: true,
    });
  }

  bool _showMissed(Map<String, dynamic> model) {
    final content = (model[NOTIFICATION_CONTENT] as Map).cast<String, dynamic>();
    final id = content[NOTIFICATION_ID] as int;
    _missed[id] = model;
    if (!api.available) return false;
    api.show(
      _missedTagOf(id),
      title: content[NOTIFICATION_TITLE] as String? ?? '',
      body: content[NOTIFICATION_BODY] as String? ?? '',
      icon: webImageUrlOf(content[NOTIFICATION_LARGE_ICON] as String?, assetUrl),
      requireInteraction: false,
      buttons: const [],
      onClick: (_) async {
        api.focusPage();
        api.close(_missedTagOf(id));
        _missed.remove(id);
        await dispatchAction(model,
            buttonKey: '', button: {NOTIFICATION_ACTION_TYPE: ActionType.Default.name});
      },
    );
    return true;
  }

  /// The core's removal hook: a cancel / dismiss of a call's notification
  /// ([removes] tells it from its model) ends the call, without a command.
  void onRemoved(bool Function(Map<String, dynamic> model) removes) {
    final calls = [
      for (final e in _calls.entries)
        if (removes(e.value.model)) e.key,
    ];
    calls.forEach(_end);
    final missed = [
      for (final e in _missed.entries)
        if (removes(e.value)) e.key,
    ];
    for (final id in missed) {
      _missed.remove(id);
      api.close(_missedTagOf(id));
    }
  }

  @override
  Future<Object?> invokeMethod(String method, [Object? arguments]) async {
    switch (method) {
      case CallKeys.methodEnd:
        final map = (arguments as Map).cast<String, dynamic>();
        final call = _end(map[CallKeys.callId] as String);
        if (call != null &&
            map[CallKeys.reason] == CallEndReason.unanswered.name &&
            call.call[CallKeys.missedNotification] == true) {
          await _createMissed(call);
        }
        return null;
      case CallKeys.methodActiveCalls:
        return [
          for (final call in _calls.values)
            {CallKeys.callId: call.callId, CallKeys.state: call.state.name},
        ];
      case CallKeys.methodVoipToken:
        return null;
      case CallKeys.methodCanUseFullScreenIntent:
      case CallKeys.methodRequestFullScreenIntent:
        return true;
      case CallKeys.methodCapabilities:
        // A page notification: no system call UI, no lock screen, no mute /
        // hold, no ringing with the page closed.
        return {'systemCallUI': false, 'lockScreen': false, 'muteAndHold': false, 'push': false};
    }
    throw MissingPluginException('No web implementation for $method');
  }
}

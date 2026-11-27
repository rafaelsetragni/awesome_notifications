import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'web_live_activity_controller.dart';

@JS('window')
external JSObject get _window;

extension type _Notification._(JSObject _) implements JSObject {
  external void close();
  external set onclick(JSFunction? handler);
  external set onclose(JSFunction? handler);
}

/// [LiveNotificationApi] over the page's notifications
/// (`new Notification(title, options)`).
///
/// Works: the notification replaced in place through its tag, silently
/// (`renotify: false`) or alerting again (`renotify: true`), kept on screen
/// with `requireInteraction` where the browser supports it (Chrome, Edge),
/// the large icon as its icon, the click on its body (focuses the page) and
/// its closing by the user.
///
/// Doesn't: action buttons (a page notification can't have `actions`: only
/// a service worker's can, and the core has none yet), a drawn progress bar
/// or a running clock (written into the body), anything with the page
/// closed (no push).
class JsLiveNotifications implements LiveNotificationApi {
  final Map<String, _Notification> _shown = {};

  JSObject? get _constructor => _window.has('Notification')
      ? _window.getProperty<JSObject>('Notification'.toJS)
      : null;

  String? get _permission {
    final permission = _constructor?.getProperty<JSAny?>('permission'.toJS);
    return permission.isA<JSString>() ? (permission as JSString).toDart : null;
  }

  @override
  bool get available => _permission == 'granted';

  @override
  Future<bool> requestPermission() async {
    final constructor = _constructor;
    if (constructor == null) return false;
    if (_permission == 'granted') return true;
    try {
      final result = await constructor.callMethod<JSPromise<JSString>>('requestPermission'.toJS).toDart;
      return result.toDart == 'granted';
    } catch (_) {
      // An old browser (callback only) or a refused request.
      return available;
    }
  }

  @override
  void show(
    String tag, {
    required String title,
    required String body,
    String? icon,
    required bool requireInteraction,
    required bool renotify,
    required void Function() onClick,
    required void Function() onClose,
  }) {
    final constructor = _constructor;
    if (constructor == null) return;
    final options = {
      'body': body,
      'tag': tag,
      'renotify': renotify,
      'requireInteraction': requireInteraction,
      if (icon != null) 'icon': icon,
    }.jsify();
    final _Notification notification;
    try {
      notification = (constructor as JSFunction).callAsConstructor<_Notification>(title.toJS, options);
    } catch (_) {
      // The browser refused it (no permission, an insecure page…).
      return;
    }
    // The one it replaces is gone without the user: no close of its own.
    _shown.remove(tag)?._detach();
    notification.onclick = ((JSObject event) {
      event.callMethod('preventDefault'.toJS);
      onClick();
    }).toJS;
    notification.onclose = ((JSObject event) {
      if (!identical(_shown[tag], notification)) return;
      _shown.remove(tag);
      onClose();
    }).toJS;
    _shown[tag] = notification;
  }

  @override
  void close(String tag) {
    final notification = _shown.remove(tag);
    if (notification == null) return;
    notification._detach();
    notification.close();
  }

  @override
  void focusPage() => _window.callMethod('focus'.toJS);
}

extension on _Notification {
  void _detach() {
    onclick = null;
    onclose = null;
  }
}

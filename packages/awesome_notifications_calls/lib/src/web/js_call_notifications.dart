import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../call_command.dart';
import 'web_call_controller.dart';

@JS('window')
external JSObject get _window;

extension type _Notification._(JSObject _) implements JSObject {
  external void close();
  external set onclick(JSFunction? handler);
}

/// [CallNotificationApi] over the page's notifications
/// (`new Notification(title, options)`).
///
/// Works: the notification (replaced in place through its tag), kept on
/// screen with `requireInteraction` where the browser supports it (Chrome,
/// Edge), the caller's avatar as its icon, and the click on its body, which
/// focuses the page and emits the core's action event.
///
/// Doesn't: the Accept / Decline / Hang up buttons. A page notification
/// can't have `actions` (the constructor throws a TypeError): only a service
/// worker's persistent notification can, and its button clicks reach the
/// worker's `notificationclick`, not the page. The core has no service
/// worker yet, so the buttons are left out and the app answers the call
/// from its own page (the body click brings it to the front). Nothing rings
/// with the page closed.
class JsCallNotifications implements CallNotificationApi {
  final Map<String, _Notification> _shown = {};

  JSObject? get _constructor => _window.has('Notification')
      ? _window.getProperty<JSObject>('Notification'.toJS)
      : null;

  @override
  bool get available {
    final constructor = _constructor;
    if (constructor == null) return false;
    final permission = constructor.getProperty<JSAny?>('permission'.toJS);
    return permission.isA<JSString>() && (permission as JSString).toDart == 'granted';
  }

  @override
  void show(
    String tag, {
    required String title,
    required String body,
    String? icon,
    required bool requireInteraction,
    required List<WebCallButton> buttons,
    required void Function(CallAction? action) onClick,
  }) {
    final constructor = _constructor;
    if (constructor == null) return;
    final options = {
      'body': body,
      'tag': tag,
      'requireInteraction': requireInteraction,
      if (icon != null) 'icon': icon,
      // No `actions`: see the class documentation.
    }.jsify();
    final _Notification notification;
    try {
      notification = (constructor as JSFunction).callAsConstructor<_Notification>(title.toJS, options);
    } catch (_) {
      // The browser refused it (no permission, an insecure page…).
      return;
    }
    notification.onclick = ((JSObject event) {
      event.callMethod('preventDefault'.toJS);
      onClick(null);
    }).toJS;
    _shown[tag] = notification;
  }

  @override
  void close(String tag) {
    final notification = _shown.remove(tag);
    if (notification == null) return;
    notification.onclick = null;
    notification.close();
  }

  @override
  void focusPage() => _window.callMethod('focus'.toJS);
}

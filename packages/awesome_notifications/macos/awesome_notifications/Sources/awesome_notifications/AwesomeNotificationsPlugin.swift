import Cocoa
import FlutterMacOS
import IosAwnCore

/// Thin Flutter bridge for macOS: the same Flutter-free IosAwnCore engine and
/// method router as iOS (UserNotifications is shared by both platforms); this
/// only adapts AppKit lifecycle and `FlutterResult`.
public class AwesomeNotificationsPlugin: NSObject, FlutterPlugin, AwesomeEventListener {

  private var channel: FlutterMethodChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "awesome_notifications",
      binaryMessenger: registrar.messenger
    )
    let instance = AwesomeNotificationsPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Forward core lifecycle events (created/displayed/tap/dismiss) to Dart.
    AwesomeEventsReceiver.shared.subscribe(listener: instance)

    // Claim the notification-center delegate before launch finishes, so a
    // notification that launched the app is captured (getInitialAction); then
    // settle the launch state once the app becomes active.
    AwesomeNotifications.shared.attachToNotificationCenter()
    NotificationCenter.default.addObserver(
      instance,
      selector: #selector(appDidBecomeActive),
      name: NSApplication.didBecomeActiveNotification,
      object: nil
    )

    // Keep the core's lifecycle in step with the app's visibility.
    let visibilityChanges: [Notification.Name] = [
      NSApplication.didBecomeActiveNotification,
      NSApplication.didResignActiveNotification,
      NSApplication.didHideNotification,
      NSApplication.didUnhideNotification,
      NSWindow.didMiniaturizeNotification,
      NSWindow.didDeminiaturizeNotification,
      NSWindow.didChangeOcclusionStateNotification,
      NSWindow.willCloseNotification,
    ]
    for name in visibilityChanges {
      NotificationCenter.default.addObserver(
        instance,
        selector: #selector(visibilityDidChange),
        name: name,
        object: nil
      )
    }
  }

  @objc private func appDidBecomeActive() {
    DispatchQueue.main.async {
      AwesomeNotifications.shared.finishLaunching()
    }
  }

  /// macOS counterpart of iOS's foreground: the user can see the app — it is
  /// not hidden and has a window on screen (not minimized, not fully covered).
  /// Otherwise it runs in the background, like an iOS app sent home.
  @objc private func visibilityDidChange() {
    // Re-read once the change settled (a closing window is still listed now).
    DispatchQueue.main.async {
      let app = NSApplication.shared
      let isVisible = !app.isHidden && app.windows.contains { window in
        window.isVisible && !window.isMiniaturized
          && window.occlusionState.contains(.visible)
      }
      AppLifeCycle.current = isVisible ? .foreground : .background
    }
  }

  // MARK: - AwesomeEventListener

  public func onNewAwesomeEvent(eventType: String, content: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.channel?.invokeMethod(eventType, arguments: content)
    }
  }

  // MARK: - Method channel

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "getPlatformVersion" {
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
      return
    }
    let handled = AwesomeMethodRouter.shared.handle(
      method: call.method,
      arguments: call.arguments
    ) { value in
      if let exception = value as? AwesomeNotificationsException {
        result(FlutterError(
          code: exception.code, message: exception.message, details: exception.detailedCode))
      } else {
        result(value)
      }
    }
    if !handled {
      result(FlutterMethodNotImplemented)
    }
  }
}

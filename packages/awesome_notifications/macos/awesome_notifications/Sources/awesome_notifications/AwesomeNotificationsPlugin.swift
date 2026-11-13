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
  }

  @objc private func appDidBecomeActive() {
    DispatchQueue.main.async {
      AwesomeNotifications.shared.finishLaunching()
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
      result(value)
    }
    if !handled {
      result(FlutterMethodNotImplemented)
    }
  }
}

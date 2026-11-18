import Flutter
import UIKit
import IosAwnCore

/// Thin Flutter bridge: translates method-channel calls into the Flutter-free
/// IosAwnCore engine. All notification logic lives in the core so it can be
/// shared with a Notification Service Extension later.
public class AwesomeNotificationsPlugin: NSObject, FlutterPlugin, AwesomeEventListener {

  private var channel: FlutterMethodChannel?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "awesome_notifications",
      binaryMessenger: registrar.messenger()
    )
    let instance = AwesomeNotificationsPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Subscribe to core lifecycle events (created/displayed/tap/dismiss) and
    // forward them to Dart.
    AwesomeEventsReceiver.shared.subscribe(listener: instance)

    // Claim the notification-center delegate now — Apple requires it before the
    // app finishes launching, so a notification that launched a killed app is
    // captured. This is what makes getInitialAction reliable, including under
    // the UIScene lifecycle. Then settle the launch state once the app becomes
    // active (deferred one run loop so a launch response is processed first).
    AwesomeNotifications.shared.attachToNotificationCenter()
    NotificationCenter.default.addObserver(
      instance,
      selector: #selector(appDidBecomeActive),
      name: UIApplication.didBecomeActiveNotification,
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
      result("iOS " + UIDevice.current.systemVersion)
      return
    }
    // The shared (iOS + macOS) router drives the core and the decorators.
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

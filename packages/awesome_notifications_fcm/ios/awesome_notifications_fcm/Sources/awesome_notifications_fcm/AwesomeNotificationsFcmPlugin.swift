import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import IosAwnCore

/// Flutter bridge for the FCM decorator (iOS). Owns the
/// `awesome_notifications_fcm` method channel and the Firebase token / topic
/// operations, forwards token refreshes and silent data to Dart, and turns
/// incoming pushes into core payloads displayed through the shared engine.
public class AwesomeNotificationsFcmPlugin: NSObject, FlutterPlugin, MessagingDelegate {

    private var channel: FlutterMethodChannel?
    private var silentHandle: Int64 = 0
    private let parser = FcmMessageParser()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: FcmDefinitions.CHANNEL_FLUTTER_PLUGIN,
            binaryMessenger: registrar.messenger()
        )
        let instance = AwesomeNotificationsFcmPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    // MARK: - Method channel

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case FcmDefinitions.CHANNEL_METHOD_INITIALIZE:
            let args = call.arguments as? [String: Any] ?? [:]
            let debug = args[FcmDefinitions.DEBUG_MODE] as? Bool ?? false
            let bgHandle = (args[FcmDefinitions.DART_BG_HANDLE] as? NSNumber)?.int64Value
            silentHandle = (args[FcmDefinitions.SILENT_HANDLE] as? NSNumber)?.int64Value ?? 0
            FcmDefaultsManager.saveHandles(
                dartBackgroundHandle: bgHandle,
                silentCallbackHandle: silentHandle,
                debug: debug
            )
            Messaging.messaging().delegate = self
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
            deliverCurrentToken()
            result(true)

        case FcmDefinitions.CHANNEL_METHOD_IS_FCM_AVAILABLE:
            result(FirebaseApp.app() != nil)

        case FcmDefinitions.CHANNEL_METHOD_GET_FCM_TOKEN:
            guard FirebaseApp.app() != nil else { result(""); return }
            Messaging.messaging().token { token, _ in result(token ?? "") }

        case FcmDefinitions.CHANNEL_METHOD_SUBSCRIBE_TOPIC:
            guard let topic = (call.arguments as? [String: Any])?[FcmDefinitions.NOTIFICATION_TOPIC] as? String else {
                result(false); return
            }
            Messaging.messaging().subscribe(toTopic: topic) { error in result(error == nil) }

        case FcmDefinitions.CHANNEL_METHOD_UNSUBSCRIBE_TOPIC:
            guard let topic = (call.arguments as? [String: Any])?[FcmDefinitions.NOTIFICATION_TOPIC] as? String else {
                result(false); return
            }
            Messaging.messaging().unsubscribe(fromTopic: topic) { error in result(error == nil) }

        case FcmDefinitions.CHANNEL_METHOD_DELETE_TOKEN:
            Messaging.messaging().deleteToken { error in result(error == nil) }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - MessagingDelegate

    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        FcmDefaultsManager.lastToken = fcmToken
        DispatchQueue.main.async { [weak self] in
            self?.channel?.invokeMethod(FcmDefinitions.CHANNEL_METHOD_NEW_FCM_TOKEN, arguments: fcmToken)
        }
    }

    // MARK: - Remote notifications (FlutterApplicationLifeCycleDelegate)

    public func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Hand APNs to Firebase and surface the raw native token to Dart.
        Messaging.messaging().apnsToken = deviceToken
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        DispatchQueue.main.async { [weak self] in
            self?.channel?.invokeMethod(FcmDefinitions.CHANNEL_METHOD_NEW_NATIVE_TOKEN, arguments: hex)
        }
    }

    public func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) -> Bool {
        var info: [String: Any] = [:]
        for (key, value) in userInfo { info["\(key)"] = value }

        let lifeCycle = currentLifeCycle()
        if parser.isDisplayable(info) {
            let notificationId = generateId(info)
            let model = parser.buildAwesomeMap(
                notificationId: notificationId,
                userInfo: info,
                lifeCycle: lifeCycle
            )
            AwesomeNotifications.shared.createNotification(model) { _ in
                completionHandler(.newData)
            }
        } else {
            let silentData = SilentDataModel()
            silentData.createdLifeCycle = lifeCycle
            silentData.fromData(info)
            // Deliver to the live app engine if possible, else a headless isolate.
            if silentHandle != 0, let channel = channel {
                var payload = silentData.toMap()
                payload[FcmDefinitions.SILENT_HANDLE] = NSNumber(value: silentHandle)
                DispatchQueue.main.async {
                    channel.invokeMethod(FcmDefinitions.CHANNEL_METHOD_SILENT_CALLBACK, arguments: payload)
                }
            } else {
                DartFcmBackgroundExecutor.shared.enqueue(silentData)
            }
            completionHandler(.newData)
        }
        return true
    }

    // MARK: - Helpers

    private func deliverCurrentToken() {
        guard FirebaseApp.app() != nil else { return }
        Messaging.messaging().token { [weak self] token, _ in
            guard let token = token else { return }
            FcmDefaultsManager.lastToken = token
            DispatchQueue.main.async {
                self?.channel?.invokeMethod(FcmDefinitions.CHANNEL_METHOD_NEW_FCM_TOKEN, arguments: token)
            }
        }
    }

    private func currentLifeCycle() -> NotificationLifeCycle {
        switch UIApplication.shared.applicationState {
        case .active: return .foreground
        case .inactive: return .foreground
        case .background: return .background
        @unknown default: return .terminated
        }
    }

    private func generateId(_ info: [String: Any]) -> Int {
        if let content = FcmJson.parseObject(info[FcmDefinitions.MODEL_CONTENT]),
           let id = content[Definitions.NOTIFICATION_ID] as? Int {
            return id
        }
        return Int(Date().timeIntervalSince1970 * 1000) & 0x7fffffff
    }
}

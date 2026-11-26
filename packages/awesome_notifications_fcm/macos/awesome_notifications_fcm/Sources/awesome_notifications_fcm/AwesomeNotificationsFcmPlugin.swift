import Cocoa
import FlutterMacOS
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import IosAwnCore
import ObjectiveC

/// Flutter bridge for the FCM decorator (macOS). Same channel, methods and
/// message handling as iOS (the parser, models and defaults are the shared iOS
/// sources); only the AppKit plumbing differs:
///  - FlutterMacOS does not forward the APNs callbacks to plugins (and Firebase's
///    GULAppDelegateSwizzler skips `didReceiveRemoteNotification` on macOS), so
///    the app delegate's two APNs callbacks are hooked here, always chaining to
///    the implementation already there (the app's own, or Firebase's proxy);
///  - macOS never launches a terminated app for a push, so silent data always
///    reaches the running app's engine (there is no headless isolate).
public class AwesomeNotificationsFcmPlugin: NSObject, FlutterPlugin, MessagingDelegate {

    /// The instance the app-delegate hooks deliver to.
    private static weak var instance: AwesomeNotificationsFcmPlugin?
    private static var isHooked = false

    private var channel: FlutterMethodChannel?
    private var silentHandle: Int64 = 0
    private let parser = FcmMessageParser()
    private static let pushProvider = FcmPushProvider()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: FcmDefinitions.CHANNEL_FLUTTER_PLUGIN,
            binaryMessenger: registrar.messenger
        )
        let instance = AwesomeNotificationsFcmPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
        AwesomeNotificationsFcmPlugin.instance = instance
        // The core then leaves to this plugin the FCM pushes it builds, instead
        // of also showing the system's raw copy.
        RemoteModelProviderRegistry.shared.register(pushProvider)
        hookAppDelegate()
    }

    // MARK: - App delegate hooks

    private static func hookAppDelegate() {
        guard !isHooked else { return }
        guard let delegate = NSApplication.shared.delegate,
              let delegateClass = object_getClass(delegate) else {
            // The delegate is set when the main nib loads; retry once it is.
            DispatchQueue.main.async { hookAppDelegate() }
            return
        }
        isHooked = true

        hook(delegateClass, "application:didRegisterForRemoteNotificationsWithDeviceToken:") {
            (application: NSApplication, argument: AnyObject) in
            if let deviceToken = argument as? Data {
                instance?.didRegister(deviceToken: deviceToken)
            }
        }
        hook(delegateClass, "application:didReceiveRemoteNotification:") {
            (application: NSApplication, argument: AnyObject) in
            if let userInfo = argument as? [String: Any] {
                instance?.didReceiveRemoteNotification(userInfo)
            }
        }
    }

    /// Makes `selector` (an `(NSApplication, id) -> Void` delegate method) call
    /// `handler` first, then whatever implementation the class already had
    /// (its own, or an inherited one).
    private static func hook(
        _ delegateClass: AnyClass,
        _ selectorName: String,
        _ handler: @escaping (NSApplication, AnyObject) -> Void
    ) {
        typealias Implementation = @convention(c) (AnyObject, Selector, NSApplication, AnyObject) -> Void
        let selector = NSSelectorFromString(selectorName)
        let previous = class_getInstanceMethod(delegateClass, selector).map {
            unsafeBitCast(method_getImplementation($0), to: Implementation.self)
        }
        let block: @convention(block) (AnyObject, NSApplication, AnyObject) -> Void = {
            target, application, argument in
            handler(application, argument)
            previous?(target, selector, application, argument)
        }
        let implementation = imp_implementationWithBlock(block)
        if !class_addMethod(delegateClass, selector, implementation, "v@:@@"),
           let method = class_getInstanceMethod(delegateClass, selector) {
            method_setImplementation(method, implementation)
        }
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
                NSApplication.shared.registerForRemoteNotifications()
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

    // MARK: - Remote notifications

    private func didRegister(deviceToken: Data) {
        // Hand APNs to Firebase and surface the raw native token to Dart.
        Messaging.messaging().apnsToken = deviceToken
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        DispatchQueue.main.async { [weak self] in
            self?.channel?.invokeMethod(FcmDefinitions.CHANNEL_METHOD_NEW_NATIVE_TOKEN, arguments: hex)
        }
    }

    private func didReceiveRemoteNotification(_ userInfo: [String: Any]) {
        Messaging.messaging().appDidReceiveMessage(userInfo)

        let lifeCycle = currentLifeCycle()
        if parser.isDisplayable(userInfo) {
            let model = parser.buildAwesomeMap(
                notificationId: generateId(userInfo),
                userInfo: userInfo,
                lifeCycle: lifeCycle
            )
            AwesomeNotifications.shared.createNotification(model) { _ in }
            removeRawCopy(of: userInfo)
            return
        }

        // Silent data: the app is running (macOS never launches it for a push),
        // so it always goes to the live engine.
        guard silentHandle != 0, let channel = channel else { return }
        let silentData = SilentDataModel()
        silentData.createdLifeCycle = lifeCycle
        silentData.fromData(userInfo)
        var payload = silentData.toMap()
        payload[FcmDefinitions.SILENT_HANDLE] = NSNumber(value: silentHandle)
        DispatchQueue.main.async {
            channel.invokeMethod(FcmDefinitions.CHANNEL_METHOD_SILENT_CALLBACK, arguments: payload)
        }
    }

    // MARK: - Helpers

    /// The system also shows a push with an alert when the app is not the
    /// active one (then the core's willPresent never runs): remove that raw
    /// copy, as the notification built here replaces it. It may land after
    /// this call, so look again a moment later.
    private func removeRawCopy(of userInfo: [String: Any]) {
        guard let messageId = userInfo[FcmDefinitions.GCM_MESSAGE_ID] as? String else { return }
        let center = UNUserNotificationCenter.current()
        let remove = {
            center.getDeliveredNotifications { delivered in
                let ids = delivered
                    .filter { $0.request.trigger is UNPushNotificationTrigger }
                    .filter { ($0.request.content.userInfo[FcmDefinitions.GCM_MESSAGE_ID] as? String) == messageId }
                    .map { $0.request.identifier }
                if !ids.isEmpty { center.removeDeliveredNotifications(withIdentifiers: ids) }
            }
        }
        remove()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: remove)
    }

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

    /// The core's lifecycle, kept by the core plugin from the app's visibility:
    /// foreground while a window is on screen; hidden, minimized or covered is
    /// background, like an iOS app sent home.
    private func currentLifeCycle() -> NotificationLifeCycle {
        return AppLifeCycle.current
    }

    private func generateId(_ info: [String: Any]) -> Int {
        if let content = FcmJson.parseObject(info[FcmDefinitions.MODEL_CONTENT]),
           let id = content[Definitions.NOTIFICATION_ID] as? Int {
            return id
        }
        return Int(Date().timeIntervalSince1970 * 1000) & 0x7fffffff
    }
}

/// Recognizes, for the core, the FCM pushes this plugin builds: displayable
/// ones that came through FCM.
final class FcmPushProvider: RemoteModelProvider {
    private let parser = FcmMessageParser()

    func model(from request: UNNotificationRequest) -> [String: Any]? {
        var userInfo: [String: Any] = [:]
        for (key, value) in request.content.userInfo {
            if let key = key as? String { userInfo[key] = value }
        }
        guard userInfo[FcmDefinitions.GCM_MESSAGE_ID] != nil, parser.isDisplayable(userInfo) else {
            return nil
        }
        return parser.buildAwesomeMap(notificationId: 0, userInfo: userInfo, lifeCycle: AppLifeCycle.current)
    }
}

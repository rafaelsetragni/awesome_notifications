import Foundation
import IosAwnCore
import UserNotifications

/// FCM in a Notification Service Extension: turns an FCM push into the core's
/// notification model, so the extension rebuilds it through the builder chain
/// (images, buttons, translations, chat messages…).
public enum AwesomeFcmExtension {
    private static let provider = FcmRemoteModelProvider()

    /// Registers the FCM push parser. Call it from `registerAddOns()`.
    public static func register() {
        RemoteModelProviderRegistry.shared.register(provider)
    }
}

/// The 0.12 name of the FCM service extension: subclass it and FCM pushes are
/// handled (override `registerAddOns` to add other add-ons, calling super).
open class DartAwesomeServiceExtension: AwesomeServiceExtension {
    open override func registerAddOns() {
        AwesomeFcmExtension.register()
    }
}

final class FcmRemoteModelProvider: RemoteModelProvider {
    private let parser = FcmMessageParser()

    func model(from request: UNNotificationRequest) -> [String: Any]? {
        var userInfo: [String: Any] = [:]
        for (key, value) in request.content.userInfo {
            if let key = key as? String { userInfo[key] = value }
        }
        guard parser.isDisplayable(userInfo) else { return nil }
        // An extension never knows the app's state: as 0.12, the push was
        // received with the app considered killed.
        return parser.buildAwesomeMap(
            notificationId: Self.notificationId(userInfo),
            userInfo: userInfo,
            lifeCycle: .terminated)
    }

    /// The content's id, or one derived from the time (like the plugin does).
    private static func notificationId(_ userInfo: [String: Any]) -> Int {
        if let content = FcmJson.parseObject(userInfo[FcmDefinitions.MODEL_CONTENT]),
           let id = content[Definitions.NOTIFICATION_ID] as? Int {
            return id
        }
        if let text = userInfo[FcmDefinitions.MODEL_CONTENT + ".id"] as? String, let id = Int(text) {
            return id
        }
        return Int(Date().timeIntervalSince1970 * 1000) & 0x7fffffff
    }
}

import Foundation
import IosAwnCore
#if os(iOS)
import PushKit
#endif

/// The payload of a VoIP push: top-level `content` and `call`, each a
/// dictionary or a JSON string, with the shapes of a created model.
public enum VoipPayload {

    /// The call's model, validated, or the reason it can't be one. A content
    /// without an id gets the callId's hash; the call always uses the system
    /// call UI (iOS requires CallKit for a VoIP push).
    public static func parse(_ payload: [AnyHashable: Any]) -> (CallNotifications.Prepared?, String?) {
        func map(_ key: String) -> [String: Any]? {
            let value = payload[key]
            if let map = value as? [String: Any] { return map }
            if let map = value as? [AnyHashable: Any] {
                var result: [String: Any] = [:]
                for (key, value) in map { if let key = key as? String { result[key] = value } }
                return result
            }
            if let json = value as? String { return JsonUtils.shared.fromJson(json) }
            return nil
        }
        guard var call = map(CallKeys.call) else { return (nil, "The VoIP push has no call") }
        call[CallKeys.systemCallUI] = true
        var content = map(Definitions.NOTIFICATION_CONTENT) ?? [:]
        if MapUtils.shared.getInt(content[Definitions.NOTIFICATION_ID]) == nil,
           let callId = call[CallKeys.callId] as? String {
            content[Definitions.NOTIFICATION_ID] = CallIds.notificationId(callId)
        }
        if content[Definitions.NOTIFICATION_CREATED_SOURCE] == nil {
            content[Definitions.NOTIFICATION_CREATED_SOURCE] = NotificationSource.callKit.rawValue
        }
        let model: [String: Any] = [Definitions.NOTIFICATION_CONTENT: content, CallKeys.call: call]
        do {
            guard let prepared = try CallNotifications.prepare(model) else { return (nil, "The VoIP push has no call") }
            return (prepared, nil)
        } catch let error as AwesomeNotificationsException {
            return (nil, error.message)
        } catch {
            return (nil, "\(error)")
        }
    }

    /// The call reported (and ended at once) for a VoIP push that carries no
    /// valid call: iOS stops delivering VoIP pushes to an app that doesn't
    /// report one for each.
    public static var placeholder: NotificationCall {
        NotificationCall(
            callId: UUID().uuidString, caller: NotificationPerson(key: "unknown", name: "Unknown"),
            handle: nil, video: false, groupName: nil, state: .incoming, startedAt: nil,
            ringTimeout: NotificationCall.defaultRingTimeout, missedNotification: false,
            controls: CallControl.allCases, commandTarget: .actionEvent, systemCallUI: true,
            texts: NotificationCall.defaultTexts)
    }

    /// A push token as hex.
    public static func hex(_ token: Data) -> String {
        token.map { String(format: "%02x", $0) }.joined()
    }
}

#if os(iOS)
/// PushKit (VoIP pushes), owned by the package: registered when the plugin
/// registers, or earlier from the app delegate (see
/// `AwesomeNotificationsCallsPlugin.registerAtLaunch`).
final class CallVoipPush: NSObject, PKPushRegistryDelegate {

    static let shared = CallVoipPush()

    private var registry: PKPushRegistry?

    func start() {
        guard registry == nil else { return }
        let registry = PKPushRegistry(queue: .main)
        registry.delegate = self
        registry.desiredPushTypes = [.voIP]
        self.registry = registry
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }
        CallManager.shared.voipToken = VoipPayload.hex(pushCredentials.token)
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        guard type == .voIP else { return }
        CallManager.shared.voipToken = nil
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType, completion: @escaping () -> Void) {
        guard type == .voIP else { completion(); return }
        let manager = CallManager.shared
        let (parsed, error) = VoipPayload.parse(payload.dictionaryPayload)
        guard let prepared = parsed else {
            NSLog("[AwesomeNotificationsCalls] Invalid VoIP push: \(error ?? "")")
            // Reported anyway (iOS requires it), and ended at once.
            guard let system = manager.system else { completion(); return }
            let uuid = UUID()
            system.reportIncoming(VoipPayload.placeholder, uuid: uuid) { _ in
                system.reportEnded(uuid: uuid, reason: .failed)
                completion()
            }
            return
        }
        // Reported to CallKit now, before anything else.
        manager.reportPushed(prepared, completion: completion)
        // Then through the core, so the created / displayed events fire.
        AwesomeNotifications.shared.createNotification(prepared.model) { _ in }
    }
}
#endif

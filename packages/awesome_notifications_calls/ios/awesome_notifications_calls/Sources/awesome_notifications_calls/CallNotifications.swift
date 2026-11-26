import Foundation
import IosAwnCore

/// The models of the call notifications (pure functions, no system call): the
/// validated call model, the notification shown where the system has no call
/// UI (macOS, iOS with `systemCallUI: false`) and the missed call notification.
public enum CallNotifications {

    /// A validated call model.
    public struct Prepared {
        public let call: NotificationCall
        /// The model with the callId in its payload and the title / body
        /// filled (the core reports it in the created / displayed events).
        public let model: [String: Any]
        /// The app's own title / body (nil: the package's).
        public let appTitle: String?
        public let appBody: String?
    }

    static func invalid(_ message: String, _ detail: String) -> AwesomeNotificationsException {
        AwesomeNotificationsException(
            code: AwesomeNotificationsException.CODE_INVALID_ARGUMENTS,
            message: message,
            detailedCode: AwesomeNotificationsException.DETAILED_INVALID_ARGUMENTS + detail)
    }

    static func content(_ model: [String: Any]) -> [String: Any] {
        (model[Definitions.NOTIFICATION_CONTENT] as? [String: Any]) ?? [:]
    }

    private static func own(_ value: Any?) -> String? {
        guard let text = value as? String, !text.isEmpty else { return nil }
        return text
    }

    /// Validates a model. Nil when it has no `call` block (not a call model:
    /// `NotificationCategory.Call` alone keeps the core's behavior). Throws the
    /// contract's refusals.
    public static func prepare(_ model: [String: Any]) throws -> Prepared? {
        guard let block = model[CallKeys.call], !(block is NSNull) else { return nil }
        if let schedule = model[CallKeys.schedule], !(schedule is NSNull) {
            throw invalid("Call notifications can't be scheduled", CallKeys.invalidSchedule)
        }
        let (parsed, error) = NotificationCall.parse(block)
        guard let call = parsed else { throw invalid(error ?? "Invalid call", CallKeys.invalidCall) }

        let original = restoredOriginal(model)
        var content = self.content(original)
        let appTitle = own(content[Definitions.NOTIFICATION_TITLE])
        let appBody = own(content[Definitions.NOTIFICATION_BODY])
        var payload: [String: Any] = [:]
        for (key, value) in (content[Definitions.NOTIFICATION_PAYLOAD] as? [String: Any]) ?? [:] {
            payload[key] = value
        }
        payload[CallKeys.payloadCallId] = call.callId
        content[Definitions.NOTIFICATION_PAYLOAD] = payload
        content[Definitions.NOTIFICATION_TITLE] = appTitle ?? call.name
        content[Definitions.NOTIFICATION_BODY] = appBody ?? call.stateText

        var prepared = original
        prepared[Definitions.NOTIFICATION_CONTENT] = content
        prepared[CallKeys.call] = call.toMap()
        return Prepared(call: call, model: prepared, appTitle: appTitle, appBody: appBody)
    }

    /// The model the app sent, from one the package transformed into a call
    /// notification (as stored in a delivered notification).
    static func restoredOriginal(_ model: [String: Any]) -> [String: Any] {
        guard model[CallKeys.transformed] as? Bool == true else { return model }
        var original = model
        var content = self.content(model)
        content[Definitions.NOTIFICATION_TITLE] = model[CallKeys.appTitle] as? String
        content[Definitions.NOTIFICATION_BODY] = model[CallKeys.appBody] as? String
        original[Definitions.NOTIFICATION_CONTENT] = content
        original.removeValue(forKey: CallKeys.transformed)
        original.removeValue(forKey: CallKeys.appTitle)
        original.removeValue(forKey: CallKeys.appBody)
        original.removeValue(forKey: Definitions.NOTIFICATION_BUTTONS)
        return original
    }

    /// The model of [call] in a new state (an accepted call turned ongoing),
    /// shown again through the core.
    public static func updated(_ model: [String: Any], call: NotificationCall,
                               appTitle: String?, appBody: String?) -> [String: Any] {
        var updated = model
        var content = self.content(model)
        content[Definitions.NOTIFICATION_TITLE] = appTitle
        content[Definitions.NOTIFICATION_BODY] = appBody
        // A new created lifecycle, as for any notification sent again.
        for key in [Definitions.NOTIFICATION_CREATED_DATE, Definitions.NOTIFICATION_CREATED_LIFECYCLE,
                    Definitions.NOTIFICATION_DISPLAYED_DATE, Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] {
            content.removeValue(forKey: key)
        }
        updated[Definitions.NOTIFICATION_CONTENT] = content
        updated[CallKeys.call] = call.toMap()
        return updated
    }

    /// The call as a notification: the app's title / body or the call's name
    /// and state, Accept / Decline while ringing (time sensitive, with the
    /// channel's sound), Hang up afterwards (silent). The app's buttons are
    /// replaced by the call's.
    public static func notificationModel(_ prepared: Prepared) -> [String: Any] {
        let call = prepared.call
        var model = prepared.model
        var content = self.content(model)
        let ringing = call.state == .incoming
        let pairs: [(CallControl, CallAction, String)] = ringing
            ? [(.accept, .accept, CallKeys.textAccept), (.decline, .decline, CallKeys.textDecline)]
            : [(.hangUp, .hangUp, CallKeys.textHangUp)]
        let buttons: [[String: Any]] = pairs.filter { call.has($0.0) }.map { _, action, text in
            [
                Definitions.NOTIFICATION_BUTTON_KEY: action.key,
                Definitions.NOTIFICATION_BUTTON_LABEL: call.text(text),
                // Accept opens the app (the call screen); the others don't.
                Definitions.NOTIFICATION_ACTION_TYPE:
                    (action == .accept ? ActionType.default : ActionType.silentAction).rawValue,
                Definitions.NOTIFICATION_AUTO_DISMISSIBLE: false,
                Definitions.NOTIFICATION_IS_DANGEROUS_OPTION: action != .accept
            ]
        }
        if ringing {
            content[Definitions.NOTIFICATION_WAKE_UP_SCREEN] = true
        } else {
            content[Definitions.NOTIFICATION_WAKE_UP_SCREEN] = false
            content[Definitions.NOTIFICATION_PLAY_SOUND] = false
        }
        model[Definitions.NOTIFICATION_CONTENT] = content
        model[Definitions.NOTIFICATION_BUTTONS] = buttons
        model[CallKeys.transformed] = true
        if let title = prepared.appTitle { model[CallKeys.appTitle] = title }
        if let body = prepared.appBody { model[CallKeys.appBody] = body }
        return model
    }

    /// The missed call notification: a regular notification on the call's
    /// channel, with the id every platform uses for it.
    public static func missedModel(_ call: NotificationCall, callModel: [String: Any]) -> [String: Any] {
        let original = content(callModel)
        var content: [String: Any] = [
            Definitions.NOTIFICATION_ID: CallIds.missedNotificationId(call.callId),
            Definitions.NOTIFICATION_TITLE: call.name,
            Definitions.NOTIFICATION_BODY: call.text(call.video ? CallKeys.textMissedVideo : CallKeys.textMissed),
            Definitions.NOTIFICATION_PAYLOAD: [CallKeys.payloadCallId: call.callId]
        ]
        if let channelKey = original[Definitions.NOTIFICATION_CHANNEL_KEY] as? String {
            content[Definitions.NOTIFICATION_CHANNEL_KEY] = channelKey
        }
        if let avatar = call.caller.avatar { content[Definitions.NOTIFICATION_LARGE_ICON] = avatar }
        return [Definitions.NOTIFICATION_CONTENT: content]
    }

    /// The notification id of a call model.
    static func id(_ model: [String: Any]) -> Int? {
        MapUtils.shared.getInt(content(model)[Definitions.NOTIFICATION_ID])
    }
}

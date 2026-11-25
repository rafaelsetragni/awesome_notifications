import Foundation
import IosAwnCore

/// Takes over the `MediaPlayer` layout on iOS and macOS: the session is shown
/// in the system's Now Playing (Control Center, lock screen, the macOS menu
/// bar) and no notification is posted. The create call answers true.
public final class MediaBuilder: NotificationBuilder {

    /// Below chat (50), above scheduling (10): localization translates first.
    public static let priority = 40

    private let sessions: () -> MediaSessions
    private let loadArtwork: Bool

    public init(inner: NotificationBuilder?, sessions: @escaping () -> MediaSessions = { .shared },
                loadArtwork: Bool = true) {
        self.sessions = sessions
        self.loadArtwork = loadArtwork
        super.init(inner: inner)
    }

    public override func build(model: [String: Any]) throws -> BuiltNotification? {
        guard let (session, prepared) = try MediaBuilder.prepare(model) else {
            return try next(model)
        }
        let artwork = loadArtwork ? NowPlaying.artwork(from: session.artwork) : nil
        let sessions = self.sessions
        let show = { sessions().update(session, model: prepared, artwork: artwork) }
        if Thread.isMainThread { show() } else { DispatchQueue.main.async(execute: show) }
        return .handled(model: prepared)
    }

    /// Validates a model and fills its content (title / body from the media,
    /// the session id in the payload). Nil when the model has neither the
    /// layout nor a `media` block (not a media model).
    public static func prepare(_ model: [String: Any]) throws -> (MediaSession, [String: Any])? {
        var content = (model[Definitions.NOTIFICATION_CONTENT] as? [String: Any]) ?? [:]
        let isMedia = content[Definitions.NOTIFICATION_LAYOUT] as? String == MediaKeys.layoutMediaPlayer
        let block = model[MediaKeys.media]

        guard block != nil, !(block is NSNull) else {
            if isMedia {
                throw invalid("The MediaPlayer layout requires a NotificationMedia", ".notificationMedia")
            }
            return nil
        }
        guard isMedia else {
            throw invalid("A NotificationMedia requires the MediaPlayer layout", ".notificationMedia.layout")
        }
        let (parsed, error) = MediaSession.parse(block)
        guard let session = parsed else {
            throw invalid(error ?? "Invalid media", ".notificationMedia")
        }

        if ((content[Definitions.NOTIFICATION_TITLE] as? String) ?? "").isEmpty {
            content[Definitions.NOTIFICATION_TITLE] = session.title
        }
        if ((content[Definitions.NOTIFICATION_BODY] as? String) ?? "").isEmpty, let artist = session.artist {
            content[Definitions.NOTIFICATION_BODY] = artist
        }
        var payload = (content[Definitions.NOTIFICATION_PAYLOAD] as? [String: Any]) ?? [:]
        payload[MediaKeys.payloadSessionId] = session.sessionId
        content[Definitions.NOTIFICATION_PAYLOAD] = payload

        var prepared = model
        prepared[Definitions.NOTIFICATION_CONTENT] = content
        return (session, prepared)
    }

    static func invalid(_ message: String, _ detail: String) -> AwesomeNotificationsException {
        AwesomeNotificationsException(
            code: AwesomeNotificationsException.CODE_INVALID_ARGUMENTS,
            message: message,
            detailedCode: AwesomeNotificationsException.DETAILED_INVALID_ARGUMENTS + detail)
    }
}

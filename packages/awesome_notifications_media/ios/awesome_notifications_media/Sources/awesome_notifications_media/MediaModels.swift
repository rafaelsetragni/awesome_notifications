import Foundation

/// Keys of the `media` block and the channel names (same names as the Dart
/// `MediaKeys`).
public enum MediaKeys {
    public static let media = "media"

    public static let sessionId = "sessionId"
    public static let title = "title"
    public static let artist = "artist"
    public static let album = "album"
    public static let artwork = "artwork"
    public static let duration = "duration"
    public static let position = "position"
    public static let playbackSpeed = "playbackSpeed"
    public static let state = "state"
    public static let controls = "controls"
    public static let skipInterval = "skipInterval"
    public static let commandTarget = "commandTarget"

    /// Added to the content payload: which session a command came from.
    public static let payloadSessionId = "mediaSessionId"
    /// Prefix of the `buttonKeyPressed` of a media command.
    public static let commandPrefix = "awn.media."

    public static let methodStop = "mediaStop"
    public static let methodUpdatePosition = "mediaUpdatePosition"
    public static let methodCapabilities = "mediaCapabilities"

    public static let commandsChannel = "awesome_notifications_media/commands"

    /// A model with a `schedule` entry can't be a media session.
    public static let schedule = "schedule"
    /// The content `createdSource` of a push (awesome_notifications_fcm).
    public static let pushSource = "firebase"
    public static let control = "control"

    public static let layoutMediaPlayer = "MediaPlayer"
}

/// A standard control the system draws (Dart `MediaControl`).
public enum MediaControl: String, CaseIterable {
    case play, pause, stop
    case skipNext, skipPrevious
    case skipForward, skipBackward
    case seekTo, fastForward, rewind

    /// The `buttonKeyPressed` of this control's commands.
    public var key: String { MediaKeys.commandPrefix + rawValue }
}

/// Where a session's commands go (Dart `MediaCommandTarget`).
public enum MediaCommandTarget: String {
    case actionEvent, stream, both

    var toActionEvent: Bool { self != .stream }
    var toStream: Bool { self != .actionEvent }
}

/// The NotificationPlayState names.
public enum MediaPlayState: String, CaseIterable {
    case unknown, none, stopped, paused, playing, forwarding, rewinding, buffering, error
    case connecting, previous, next, skippingToQueueItem

    /// Whether the position advances (at the session's speed).
    var isAdvancing: Bool { self == .playing || self == .forwarding || self == .rewinding }
}

/// The `media` block of a model, validated like the Dart side.
public struct MediaSession: Equatable {
    public let sessionId: String
    public let title: String
    public let artist: String?
    public let album: String?
    public let artwork: String?
    /// Milliseconds; nil for a live stream.
    public let duration: Int?
    /// Milliseconds, at the time of the call.
    public var position: Int
    public let playbackSpeed: Double
    public let state: MediaPlayState
    public let controls: [MediaControl]
    /// Milliseconds.
    public let skipInterval: Int
    public let commandTarget: MediaCommandTarget

    /// Parses and validates the block. The error is the message to report.
    public static func parse(_ block: Any?) -> (MediaSession?, String?) {
        guard let map = block as? [String: Any] else { return (nil, "The media is not a map") }
        func string(_ key: String) -> String? {
            (map[key] as? String).flatMap { $0.isEmpty ? nil : $0 }
        }
        func int(_ key: String) -> Int? {
            if let value = map[key] as? Int { return value }
            if let value = map[key] as? NSNumber { return value.intValue }
            return nil
        }
        guard let sessionId = map[MediaKeys.sessionId] as? String,
              !sessionId.trimmingCharacters(in: .whitespaces).isEmpty else {
            return (nil, "The media session needs a non-empty sessionId")
        }
        guard let title = map[MediaKeys.title] as? String,
              !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            return (nil, "The media needs a non-empty title")
        }
        let position = int(MediaKeys.position) ?? 0
        if position < 0 { return (nil, "The media position can't be negative") }
        let duration = int(MediaKeys.duration)
        if let duration = duration {
            if duration <= 0 { return (nil, "The media duration must be positive (leave it out for a live stream)") }
            if position > duration { return (nil, "The media position is past its duration") }
        }
        guard let state = MediaPlayState(rawValue: (map[MediaKeys.state] as? String) ?? "") else {
            return (nil, "Unknown media state \"\(map[MediaKeys.state] ?? "")\"")
        }
        let speed = (map[MediaKeys.playbackSpeed] as? NSNumber)?.doubleValue
            ?? (state == .playing ? 1.0 : 0.0)
        if speed < 0 { return (nil, "The playback speed can't be negative") }
        var controls: [MediaControl] = []
        for raw in (map[MediaKeys.controls] as? [Any]) ?? [] {
            guard let control = MediaControl(rawValue: (raw as? String) ?? "") else {
                return (nil, "Unknown media control \"\(raw)\"")
            }
            if !controls.contains(control) { controls.append(control) }
        }
        let skipInterval = int(MediaKeys.skipInterval) ?? 15000
        if skipInterval <= 0 { return (nil, "The skip interval must be positive") }
        let targetName = (map[MediaKeys.commandTarget] as? String) ?? MediaCommandTarget.actionEvent.rawValue
        guard let target = MediaCommandTarget(rawValue: targetName) else {
            return (nil, "Unknown media commandTarget \"\(targetName)\"")
        }
        return (MediaSession(
            sessionId: sessionId, title: title,
            artist: string(MediaKeys.artist), album: string(MediaKeys.album),
            artwork: string(MediaKeys.artwork), duration: duration, position: position,
            playbackSpeed: speed, state: state, controls: controls,
            skipInterval: skipInterval, commandTarget: target), nil)
    }

    /// The rate the system advances the position at (0 while not playing).
    public var rate: Double { state.isAdvancing ? playbackSpeed : 0 }
}

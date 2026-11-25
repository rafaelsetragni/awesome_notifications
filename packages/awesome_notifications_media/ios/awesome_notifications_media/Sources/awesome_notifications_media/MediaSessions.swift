import Foundation
import MediaPlayer
import IosAwnCore

/// The live media sessions and the one that owns Now Playing (single per app:
/// the last session updated). Main thread only.
public final class MediaSessions {

    public static let shared = MediaSessions()

    /// The action event of a command: (model, buttonKey, input, button).
    public typealias Dispatcher = ([String: Any], String, String?, [String: Any]) -> Void

    struct Entry {
        var session: MediaSession
        /// The notification model the session was created with.
        let model: [String: Any]
    }

    private var entries: [String: Entry] = [:]
    public private(set) var ownerId: String?

    /// Null until the first session (the system objects are created lazily).
    private var surfaceStore: NowPlayingSurface?
    private let makeSurface: (MediaSessions) -> NowPlayingSurface
    let dispatch: Dispatcher
    /// The EventChannel sink while Dart listens.
    public var streamSink: (([String: Any]) -> Void)?

    public convenience init() {
        self.init(
            surface: { sessions in
                SystemNowPlaying { command, event in sessions.handle(command, event: event) }
            },
            dispatch: { model, key, input, button in
                AwesomeNotifications.shared.dispatchAction(
                    model: model, buttonKey: key, input: input, button: button)
            })
    }

    init(surface: @escaping (MediaSessions) -> NowPlayingSurface, dispatch: @escaping Dispatcher) {
        self.makeSurface = surface
        self.dispatch = dispatch
    }

    private var surface: NowPlayingSurface {
        if let surface = surfaceStore { return surface }
        let surface = makeSurface(self)
        surfaceStore = surface
        return surface
    }

    func session(_ id: String) -> MediaSession? { entries[id]?.session }

    /// Creates or updates a session; it takes over Now Playing.
    public func update(_ session: MediaSession, model: [String: Any], artwork: MPMediaItemArtwork?) {
        entries[session.sessionId] = Entry(session: session, model: model)
        ownerId = session.sessionId
        surface.show(session, artwork: artwork)
    }

    /// Releases a session; Now Playing is cleared when it owned it.
    public func stop(_ sessionId: String) {
        entries.removeValue(forKey: sessionId)
        guard ownerId == sessionId else { return }
        ownerId = nil
        surface.show(nil, artwork: nil)
    }

    /// Ends the sessions whose notification the app dismissed or cancelled,
    /// as `stop` does, whatever their state.
    public func remove(_ removal: NotificationRemoval) {
        let ids = entries.filter { _, entry in
            let content = (entry.model[Definitions.NOTIFICATION_CONTENT] as? [String: Any]) ?? [:]
            switch removal {
            case .all:
                return true
            case .id(let id):
                return MapUtils.shared.getInt(content[Definitions.NOTIFICATION_ID]) == id
            case .channelKey(let key):
                return content[Definitions.NOTIFICATION_CHANNEL_KEY] as? String == key
            case .groupKey(let key):
                return content[Definitions.NOTIFICATION_GROUP_KEY] as? String == key
            }
        }.keys
        for id in ids { stop(id) }
    }

    /// Moves a session's position only (state and speed are kept).
    public func updatePosition(_ sessionId: String, position: Int) {
        guard var entry = entries[sessionId] else { return }
        var position = max(0, position)
        if let duration = entry.session.duration { position = min(position, duration) }
        entry.session.position = position
        entries[sessionId] = entry
        if ownerId == sessionId { surface.updateElapsed(milliseconds: position) }
    }

    func handle(_ command: RemoteCommand, event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        if let seek = event as? MPSeekCommandEvent, seek.type == .endSeeking { return .success }
        let position = (event as? MPChangePlaybackPositionCommandEvent)
            .map { Int(($0.positionTime * 1000).rounded()) }
        return handle(command, position: position) ? .success : .noActionableNowPlayingItem
    }

    /// Delivers a command of the owner session to its targets. False without
    /// an owner.
    @discardableResult
    public func handle(_ command: RemoteCommand, position: Int? = nil) -> Bool {
        guard let id = ownerId, let entry = entries[id] else { return false }
        let control = NowPlaying.control(for: command, state: entry.session.state)
        let position = control == .seekTo ? position : nil
        if entry.session.commandTarget.toActionEvent {
            let action = MediaSessions.action(control, position: position)
            dispatch(entry.model, action.key, action.input, action.button)
        }
        if entry.session.commandTarget.toStream, let sink = streamSink {
            sink(MediaSessions.streamEvent(control, sessionId: id, position: position))
        }
        return true
    }

    /// The action event data of a control: key, input (seekTo's target in ms)
    /// and the synthetic button that keeps the notification.
    public static func action(_ control: MediaControl, position: Int?)
        -> (key: String, input: String?, button: [String: Any]) {
        let input = control == .seekTo ? position.map(String.init) : nil
        return (control.key, input, [
            Definitions.NOTIFICATION_BUTTON_KEY: control.key,
            Definitions.NOTIFICATION_ACTION_TYPE: ActionType.silentAction.rawValue,
            Definitions.NOTIFICATION_AUTO_DISMISSIBLE: false
        ])
    }

    /// The EventChannel event of a control.
    public static func streamEvent(_ control: MediaControl, sessionId: String, position: Int?) -> [String: Any] {
        var event: [String: Any] = [MediaKeys.control: control.rawValue, MediaKeys.sessionId: sessionId]
        if let position = position { event[MediaKeys.position] = position }
        return event
    }
}

extension MediaSessions: NotificationRemovalListener {
    public func onNotificationsRemoved(_ removal: NotificationRemoval, cancel: Bool) {
        if Thread.isMainThread { remove(removal) } else { DispatchQueue.main.async { self.remove(removal) } }
    }
}

import Foundation
import MediaPlayer
import IosAwnCore

/// The system remote commands the media controls map to.
public enum RemoteCommand: CaseIterable {
    case play, pause, togglePlayPause, stop
    case nextTrack, previousTrack
    case skipForward, skipBackward
    case changePlaybackPosition
    case seekForward, seekBackward
}

/// Pure mapping between a media session and the system's Now Playing.
public enum NowPlaying {

    /// The commands to enable for [controls]; every other one is disabled.
    /// Track and second skips share one slot per side: with both, the track
    /// buttons win.
    public static func commands(for controls: [MediaControl]) -> Set<RemoteCommand> {
        let has = Set(controls)
        var commands: Set<RemoteCommand> = []
        if has.contains(.play) { commands.insert(.play) }
        if has.contains(.pause) { commands.insert(.pause) }
        if has.contains(.play) && has.contains(.pause) { commands.insert(.togglePlayPause) }
        if has.contains(.stop) { commands.insert(.stop) }
        if has.contains(.skipNext) { commands.insert(.nextTrack) }
        if has.contains(.skipPrevious) { commands.insert(.previousTrack) }
        if has.contains(.skipForward) && !has.contains(.skipNext) { commands.insert(.skipForward) }
        if has.contains(.skipBackward) && !has.contains(.skipPrevious) { commands.insert(.skipBackward) }
        if has.contains(.seekTo) { commands.insert(.changePlaybackPosition) }
        if has.contains(.fastForward) { commands.insert(.seekForward) }
        if has.contains(.rewind) { commands.insert(.seekBackward) }
        return commands
    }

    /// The control a command reports. `togglePlayPause` resolves against the
    /// session's state: pause while it plays, play otherwise.
    public static func control(for command: RemoteCommand, state: MediaPlayState) -> MediaControl {
        switch command {
        case .play: return .play
        case .pause: return .pause
        case .togglePlayPause: return state.isAdvancing ? .pause : .play
        case .stop: return .stop
        case .nextTrack: return .skipNext
        case .previousTrack: return .skipPrevious
        case .skipForward: return .skipForward
        case .skipBackward: return .skipBackward
        case .changePlaybackPosition: return .seekTo
        case .seekForward: return .fastForward
        case .seekBackward: return .rewind
        }
    }

    /// `nowPlayingInfo` of a session (times in seconds).
    public static func info(for session: MediaSession, artwork: MPMediaItemArtwork? = nil) -> [String: Any] {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: session.title,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: seconds(session.position),
            MPNowPlayingInfoPropertyPlaybackRate: session.rate,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
            MPNowPlayingInfoPropertyIsLiveStream: session.duration == nil
        ]
        if let artist = session.artist { info[MPMediaItemPropertyArtist] = artist }
        if let album = session.album { info[MPMediaItemPropertyAlbumTitle] = album }
        if let duration = session.duration { info[MPMediaItemPropertyPlaybackDuration] = seconds(duration) }
        if let artwork = artwork { info[MPMediaItemPropertyArtwork] = artwork }
        return info
    }

    #if os(macOS)
    /// macOS also shows the playback state (iOS reads the audio session).
    public static func playbackState(for state: MediaPlayState) -> MPNowPlayingPlaybackState {
        switch state {
        case .playing, .forwarding, .rewinding: return .playing
        case .paused: return .paused
        case .stopped, .none, .error: return .stopped
        case .buffering, .connecting: return .interrupted
        case .unknown, .previous, .next, .skippingToQueueItem: return .unknown
        }
    }
    #endif

    public static func seconds(_ millis: Int) -> Double { Double(millis) / 1000 }

    /// The cover art, loaded from a media source (asset://, file://, https://,
    /// resource://). Blocking: call it off the main thread.
    public static func artwork(from source: String?) -> MPMediaItemArtwork? {
        guard let source = source,
              let image = BitmapUtils.shared.getBitmapFromSource(source) else { return nil }
        return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }
}

/// What the media logic drives: the system's Now Playing (or a fake in tests).
public protocol NowPlayingSurface: AnyObject {
    /// Shows [session] (nil clears Now Playing and disables every command).
    func show(_ session: MediaSession?, artwork: MPMediaItemArtwork?)
    /// Moves the elapsed time of what is shown, keeping the rest.
    func updateElapsed(milliseconds: Int)
}

/// The system's Now Playing: `MPNowPlayingInfoCenter` + `MPRemoteCommandCenter`.
/// Main thread only.
public final class SystemNowPlaying: NowPlayingSurface {

    /// Receives every command of the enabled controls.
    private let onCommand: (RemoteCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    private var targets: [(MPRemoteCommand, Any)] = []

    public init(onCommand: @escaping (RemoteCommand, MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus) {
        self.onCommand = onCommand
    }

    private var infoCenter: MPNowPlayingInfoCenter { .default() }

    public func show(_ session: MediaSession?, artwork: MPMediaItemArtwork?) {
        let center = MPRemoteCommandCenter.shared()
        for (command, target) in targets { command.removeTarget(target) }
        targets.removeAll()
        let enabled = session.map { NowPlaying.commands(for: $0.controls) } ?? []
        for kind in RemoteCommand.allCases {
            let command = Self.command(kind, in: center)
            command.isEnabled = enabled.contains(kind)
            guard enabled.contains(kind) else { continue }
            if let skip = command as? MPSkipIntervalCommand, let session = session {
                skip.preferredIntervals = [NSNumber(value: NowPlaying.seconds(session.skipInterval))]
            }
            let target = command.addTarget { [weak self] event in
                self?.onCommand(kind, event) ?? .commandFailed
            }
            targets.append((command, target))
        }
        guard let session = session else {
            infoCenter.nowPlayingInfo = nil
            #if os(macOS)
            infoCenter.playbackState = .stopped
            #endif
            return
        }
        infoCenter.nowPlayingInfo = NowPlaying.info(for: session, artwork: artwork)
        #if os(macOS)
        infoCenter.playbackState = NowPlaying.playbackState(for: session.state)
        #endif
    }

    public func updateElapsed(milliseconds: Int) {
        guard var info = infoCenter.nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NowPlaying.seconds(milliseconds)
        infoCenter.nowPlayingInfo = info
    }

    static func command(_ kind: RemoteCommand, in center: MPRemoteCommandCenter) -> MPRemoteCommand {
        switch kind {
        case .play: return center.playCommand
        case .pause: return center.pauseCommand
        case .togglePlayPause: return center.togglePlayPauseCommand
        case .stop: return center.stopCommand
        case .nextTrack: return center.nextTrackCommand
        case .previousTrack: return center.previousTrackCommand
        case .skipForward: return center.skipForwardCommand
        case .skipBackward: return center.skipBackwardCommand
        case .changePlaybackPosition: return center.changePlaybackPositionCommand
        case .seekForward: return center.seekForwardCommand
        case .seekBackward: return center.seekBackwardCommand
        }
    }
}

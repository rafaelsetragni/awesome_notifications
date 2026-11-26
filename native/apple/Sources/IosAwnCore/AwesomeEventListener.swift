import Foundation

/// Listener for notification lifecycle events. Mirrors the original IosAwnCore
/// `AwesomeEventListener`: the Flutter plugin implements it and forwards each
/// event to the method channel.
public protocol AwesomeEventListener: AnyObject {
    func onNewAwesomeEvent(eventType: String, content: [String: Any])
}

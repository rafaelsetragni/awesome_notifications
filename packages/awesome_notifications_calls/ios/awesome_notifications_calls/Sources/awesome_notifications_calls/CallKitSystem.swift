#if os(iOS)
import Foundation
import AVFoundation
import CallKit
import IosAwnCore

extension CallEndReason {
    /// CallKit's reason (same raw values).
    var cxReason: CXCallEndedReason { CXCallEndedReason(rawValue: rawValue) ?? .failed }
}

extension NotificationPersonHandle {
    /// CallKit's handle of a person: phone number, e-mail address or generic.
    var cxHandle: CXHandle {
        switch type {
        case .phoneNumber: return CXHandle(type: .phoneNumber, value: value)
        case .emailAddress: return CXHandle(type: .emailAddress, value: value)
        case .unknown: return CXHandle(type: .generic, value: value)
        }
    }
}

/// CallKit: one provider per app (the system's incoming / in-call UI, the
/// lock screen, Recents, Bluetooth and CarPlay) and a call controller for the
/// app's own changes. The provider's actions go to the `CallManager`, which
/// tells the user's ones from the app's coming back.
final class CallKitSystem: NSObject, CallSystem, CXProviderDelegate {

    private let provider: CXProvider
    private let controller = CXCallController()
    private unowned let manager: CallManager

    init(manager: CallManager) {
        self.manager = manager
        let configuration: CXProviderConfiguration
        if #available(iOS 14.0, *) {
            // The app's name is the provider's.
            configuration = CXProviderConfiguration()
        } else {
            let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Call"
            configuration = CXProviderConfiguration(localizedName: name)
        }
        configuration.supportsVideo = true
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.phoneNumber, .emailAddress, .generic]
        configuration.includesCallsInRecents = true
        // nil: the system's ringtone.
        configuration.ringtoneSound = nil
        provider = CXProvider(configuration: configuration)
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    static func update(_ call: NotificationCall) -> CXCallUpdate {
        let update = CXCallUpdate()
        update.remoteHandle = call.systemHandle.cxHandle
        update.localizedCallerName = call.name
        update.hasVideo = call.video
        update.supportsHolding = call.has(.hold)
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.supportsDTMF = false
        return update
    }

    // MARK: - CallSystem (the app's changes)

    func reportIncoming(_ call: NotificationCall, uuid: UUID, completion: @escaping (Error?) -> Void) {
        provider.reportNewIncomingCall(with: uuid, update: CallKitSystem.update(call)) { error in
            if let error = error { NSLog("[AwesomeNotificationsCalls] Incoming call refused: \(error)") }
            if Thread.isMainThread { completion(error) } else { DispatchQueue.main.async { completion(error) } }
        }
    }

    func update(_ call: NotificationCall, uuid: UUID) {
        provider.reportCall(with: uuid, updated: CallKitSystem.update(call))
    }

    func startOutgoing(_ call: NotificationCall, uuid: UUID) {
        let start = CXStartCallAction(call: uuid, handle: call.systemHandle.cxHandle)
        start.isVideo = call.video
        start.contactIdentifier = call.name
        request(start) { [weak self] in
            self?.provider.reportCall(with: uuid, updated: CallKitSystem.update(call))
        }
    }

    func reportConnected(uuid: UUID, at date: Date) {
        provider.reportOutgoingCall(with: uuid, connectedAt: date)
    }

    func answer(uuid: UUID) {
        request(CXAnswerCallAction(call: uuid))
    }

    func setHeld(uuid: UUID, onHold: Bool) {
        request(CXSetHeldCallAction(call: uuid, onHold: onHold))
    }

    func reportEnded(uuid: UUID, reason: CallEndReason) {
        provider.reportCall(with: uuid, endedAt: Date(), reason: reason.cxReason)
    }

    private func request(_ action: CXCallAction, then: (() -> Void)? = nil) {
        controller.request(CXTransaction(action: action)) { error in
            if let error = error {
                NSLog("[AwesomeNotificationsCalls] \(type(of: action)) failed: \(error)")
                return
            }
            if let then = then { DispatchQueue.main.async(execute: then) }
        }
    }

    // MARK: - CXProviderDelegate (the user's actions, and the app's coming back)

    func providerDidReset(_ provider: CXProvider) {
        manager.systemReset()
    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        // Only the app starts calls: report it connecting.
        provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        if manager.systemAnswered(action.callUUID) { action.fulfill() } else { action.fail() }
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        manager.systemEnded(action.callUUID)
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        if manager.systemHeld(action.callUUID, onHold: action.isOnHold) { action.fulfill() } else { action.fail() }
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        if manager.systemMuted(action.callUUID, muted: action.isMuted) { action.fulfill() } else { action.fail() }
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        manager.systemAudio(activated: true)
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        manager.systemAudio(activated: false)
    }
}
#endif

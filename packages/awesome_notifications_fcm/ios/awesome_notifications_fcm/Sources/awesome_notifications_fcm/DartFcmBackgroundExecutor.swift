import Foundation
import Flutter

/// Runs the Dart silent-data handler in a headless background isolate.
///
/// When a silent (data-only) push arrives while no Flutter UI engine can consume
/// it (app terminated), this spins up a dedicated headless `FlutterEngine` at the
/// stored `silentPushBackgroundMain` entry point and drains a queue of silent
/// messages over the `AWFcmReverse` channel, one at a time, then tears it down.
final class DartFcmBackgroundExecutor: NSObject {
    static let shared = DartFcmBackgroundExecutor()

    private var engine: FlutterEngine?
    private var channel: FlutterMethodChannel?
    private var queue: [[String: Any]] = []
    private var isRunning = false
    private var silentHandle: Int64 = 0

    private let lock = NSLock()

    /// Enqueues one silent message and starts the isolate if it is not running.
    func enqueue(_ silentData: SilentDataModel) {
        let dartHandle = FcmDefaultsManager.dartBackgroundHandle
        silentHandle = FcmDefaultsManager.silentCallbackHandle
        guard dartHandle != 0, silentHandle != 0 else { return }

        lock.lock()
        queue.append(silentData.toMap())
        let shouldStart = !isRunning
        if shouldStart { isRunning = true }
        lock.unlock()

        if shouldStart {
            DispatchQueue.main.async { [weak self] in self?.startIsolate(dartHandle) }
        }
    }

    private func startIsolate(_ dartCallbackHandle: Int64) {
        guard let info = FlutterCallbackCache.lookupCallbackInformation(dartCallbackHandle) else {
            lock.lock(); isRunning = false; lock.unlock()
            return
        }
        let engine = FlutterEngine(
            name: "AwnFcmBackgroundEngine",
            project: nil,
            allowHeadlessExecution: true
        )
        self.engine = engine
        engine.run(withEntrypoint: info.callbackName, libraryURI: info.callbackLibraryPath)

        let channel = FlutterMethodChannel(
            name: FcmDefinitions.DART_FCM_REVERSE_CHANNEL,
            binaryMessenger: engine.binaryMessenger
        )
        self.channel = channel
        channel.setMethodCallHandler { [weak self] call, result in
            if call.method == FcmDefinitions.CHANNEL_METHOD_PUSH_NEXT_DATA {
                result(true)
                self?.dischargeNext()
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func dischargeNext() {
        lock.lock()
        let next = queue.isEmpty ? nil : queue.removeFirst()
        lock.unlock()

        guard var payload = next else {
            closeIsolate()
            return
        }
        payload[FcmDefinitions.SILENT_HANDLE] = NSNumber(value: silentHandle)
        DispatchQueue.main.async { [weak self] in
            self?.channel?.invokeMethod(
                FcmDefinitions.CHANNEL_METHOD_SILENT_CALLBACK,
                arguments: payload
            ) { _ in
                self?.dischargeNext()
            }
        }
    }

    private func closeIsolate() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel?.setMethodCallHandler(nil)
            self.channel = nil
            self.engine?.destroyContext()
            self.engine = nil

            self.lock.lock()
            let hasMore = !self.queue.isEmpty
            self.isRunning = hasMore
            self.lock.unlock()

            if hasMore {
                let handle = FcmDefaultsManager.dartBackgroundHandle
                if handle != 0 { self.startIsolate(handle) }
            }
        }
    }
}

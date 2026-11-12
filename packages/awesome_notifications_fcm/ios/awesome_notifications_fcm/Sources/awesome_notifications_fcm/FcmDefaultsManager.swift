import Foundation

/// Persists the registered background callback handles and flags so a headless
/// isolate can be started to deliver silent data while the app is terminated.
enum FcmDefaultsManager {
    private static let keyDebug = "awn_fcm_debug"
    private static let keyBgHandle = "awn_fcm_dartBackgroundHandle"
    private static let keySilentHandle = "awn_fcm_silentCallbackHandle"
    private static let keyLastToken = "awn_fcm_lastToken"

    private static var defaults: UserDefaults { UserDefaults.standard }

    static func saveHandles(dartBackgroundHandle: Int64?, silentCallbackHandle: Int64?, debug: Bool) {
        defaults.set(debug, forKey: keyDebug)
        if let h = dartBackgroundHandle { defaults.set(NSNumber(value: h), forKey: keyBgHandle) }
        if let h = silentCallbackHandle { defaults.set(NSNumber(value: h), forKey: keySilentHandle) }
    }

    static var dartBackgroundHandle: Int64 {
        (defaults.object(forKey: keyBgHandle) as? NSNumber)?.int64Value ?? 0
    }

    static var silentCallbackHandle: Int64 {
        (defaults.object(forKey: keySilentHandle) as? NSNumber)?.int64Value ?? 0
    }

    static var isDebug: Bool { defaults.bool(forKey: keyDebug) }

    static var lastToken: String? {
        get { defaults.string(forKey: keyLastToken) }
        set { defaults.set(newValue, forKey: keyLastToken) }
    }
}

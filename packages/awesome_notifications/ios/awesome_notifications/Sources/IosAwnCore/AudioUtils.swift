import Foundation
import UserNotifications

/// Resolves a sound reference (`resource://`, `asset://`, `file://`,
/// `http(s)://`) into a notification sound, ported from 0.12 `AudioUtils`
/// with its quirks: a network sound plays the default sound, and a resource,
/// asset or file that is not found falls back to the default sound too.
public final class AudioUtils {
    public static let shared = AudioUtils()
    private init() {}

    private enum Source { case network, file, resource, asset, unknown }

    public func getSoundFromSource(_ soundPath: String?) -> UNNotificationSound? {
        guard let soundPath = soundPath, !StringUtils.shared.isNullOrEmpty(soundPath) else {
            return nil
        }
        switch sourceType(soundPath) {
        case .resource: return soundFromResource(soundPath)
        case .asset: return soundFromAsset(soundPath)
        case .file: return soundFromFile(soundPath)
        case .network: return soundFromUrl(soundPath)
        case .unknown: return nil
        }
    }

    // 0.12 MediaUtils.getMediaSourceType: case-insensitive prefixes, in order.
    private func sourceType(_ path: String) -> Source {
        if matches(path, "^https?:\\/\\/") { return .network }
        if matches(path, "^file:\\/\\/") { return .file }
        if matches(path, "^resource:\\/\\/") { return .resource }
        if matches(path, "^asset:\\/\\/") { return .asset }
        return .unknown
    }

    private func soundFromUrl(_ path: String) -> UNNotificationSound? {
        // 0.12 never downloads it: any non-empty URL plays the default sound.
        let rest = replacing(path, "^https?:\\/\\/", with: "")
        return StringUtils.shared.isNullOrEmpty(rest) ? nil : UNNotificationSound.default
    }

    private func soundFromFile(_ path: String) -> UNNotificationSound? {
        let realPath = replacing(path, "^(file:\\/\\/)(.*)", with: "$2")
        if StringUtils.shared.isNullOrEmpty(realPath) { return nil }
        return soundFromFile(realPath: realPath)
    }

    private func soundFromFile(realPath: String) -> UNNotificationSound? {
        if FileManager.default.fileExists(atPath: realPath) {
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: realPath))
        }
        return UNNotificationSound.default
    }

    private func soundFromAsset(_ path: String) -> UNNotificationSound? {
        let assetPath = replacing(path, "^(asset:\\/\\/)(.*)", with: "$2")
        if StringUtils.shared.isNullOrEmpty(assetPath) { return nil }
        // Flutter bundles its assets under App.framework/flutter_assets
        // (inside Contents/…/Resources on macOS).
        #if os(macOS)
        let root = Bundle.main.bundlePath
            + "/Contents/Frameworks/App.framework/Resources/flutter_assets/"
        #else
        let root = Bundle.main.bundlePath + "/Frameworks/App.framework/flutter_assets/"
        #endif
        return soundFromFile(realPath: root + assetPath)
    }

    private func soundFromResource(_ path: String) -> UNNotificationSound? {
        // resource://[folder/]name → the last path component, as an .aiff of
        // the app bundle; the default sound when the bundle lacks it.
        var name = replacing(path, "^(resource:\\/\\/)(.*)", with: "$2")
        name = replacing(name, "^.*\\/([^\\/]+)$", with: "$1")
        if let url = Bundle.main.url(forResource: name, withExtension: "aiff") {
            return UNNotificationSound(
                named: UNNotificationSoundName(rawValue: url.lastPathComponent))
        }
        return UNNotificationSound.default
    }

    private func matches(_ value: String, _ pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        else { return false }
        let range = NSRange(location: 0, length: value.utf16.count)
        return regex.firstMatch(in: value, options: [], range: range) != nil
    }

    private func replacing(_ value: String, _ pattern: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        else { return value }
        let range = NSRange(location: 0, length: value.utf16.count)
        return regex.stringByReplacingMatches(
            in: value, options: [], range: range, withTemplate: template)
    }
}

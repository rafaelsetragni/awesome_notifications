import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Loads an image from a media reference, supporting the four media sources by
/// scheme prefix: `https://` (network), `asset://` (Flutter asset),
/// `file://` (local file) and `resource://name` (bundled resource). Mirrors the
/// original IosAwnCore BitmapUtils.
///
/// NOTE: network/file decoding does I/O; call off the main thread.
public final class BitmapUtils {
    public static let shared = BitmapUtils()
    private init() {}

    private enum MediaSource { case network, file, asset, resource, unknown }

    #if canImport(UIKit)
    public func getBitmapFromSource(_ path: String?) -> UIImage? {
        guard let path = path, !path.isEmpty else { return nil }
        switch mediaSource(path) {
        case .network: return imageFromUrl(clean(path))
        case .file: return imageFromFile(clean(path))
        case .asset: return imageFromAsset(clean(path))
        case .resource: return imageFromResource(clean(path))
        case .unknown: return nil
        }
    }

    private func imageFromUrl(_ url: String) -> UIImage? {
        guard let url = URL(string: url),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func imageFromFile(_ path: String) -> UIImage? {
        guard FileManager.default.fileExists(atPath: path),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        else { return nil }
        return UIImage(data: data)
    }

    private func imageFromAsset(_ assetPath: String) -> UIImage? {
        // Flutter bundles its assets under App.framework/flutter_assets.
        let realPath = Bundle.main.bundlePath
            + "/Frameworks/App.framework/flutter_assets/" + assetPath
        return imageFromFile(realPath)
    }

    private func imageFromResource(_ reference: String) -> UIImage? {
        // resource://[type/]name → use the last path component as the asset name.
        let name = reference.components(separatedBy: "/").last ?? reference
        return UIImage(named: name)
    }
    #endif

    private func mediaSource(_ path: String) -> MediaSource {
        let lower = path.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") { return .network }
        if lower.hasPrefix("file://") { return .file }
        if lower.hasPrefix("resource://") { return .resource }
        if lower.hasPrefix("asset://") { return .asset }
        return .unknown
    }

    /// Strips the scheme prefix (network URLs are kept whole).
    private func clean(_ path: String) -> String {
        let lower = path.lowercased()
        if lower.hasPrefix("http") { return path }
        if lower.hasPrefix("asset://") { return String(path.dropFirst("asset://".count)) }
        if lower.hasPrefix("file://") { return String(path.dropFirst("file://".count)) }
        if lower.hasPrefix("resource://") { return String(path.dropFirst("resource://".count)) }
        return path
    }
}

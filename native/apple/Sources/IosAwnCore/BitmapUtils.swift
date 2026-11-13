import Foundation
#if canImport(UIKit)
import UIKit
/// The platform image type: UIImage on iOS, NSImage on macOS.
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
/// The platform image type: UIImage on iOS, NSImage on macOS.
public typealias PlatformImage = NSImage
#endif

/// Loads an image from a media reference, supporting the four media sources by
/// scheme prefix: `https://` (network), `asset://` (Flutter asset),
/// `file://` (local file) and `resource://name` (bundled resource). Mirrors the
/// original IosAwnCore BitmapUtils, on iOS (UIKit) and macOS (AppKit).
///
/// NOTE: network/file decoding does I/O; call off the main thread.
public final class BitmapUtils {
    public static let shared = BitmapUtils()
    private init() {}

    private enum MediaSource { case network, file, asset, resource, unknown }

    #if canImport(UIKit) || canImport(AppKit)
    public func getBitmapFromSource(_ path: String?) -> PlatformImage? {
        guard let path = path, !path.isEmpty else { return nil }
        switch mediaSource(path) {
        case .network: return imageFromUrl(clean(path))
        case .file: return imageFromFile(clean(path))
        case .asset: return imageFromAsset(clean(path))
        case .resource: return imageFromResource(clean(path))
        case .unknown: return nil
        }
    }

    /// PNG bytes of an image (what a notification attachment is written as).
    public func pngData(_ image: PlatformImage) -> Data? {
        #if canImport(UIKit)
        return image.pngData()
        #else
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
        #endif
    }

    private func imageFromUrl(_ url: String) -> PlatformImage? {
        guard let url = URL(string: url),
              let data = try? Data(contentsOf: url) else { return nil }
        return PlatformImage(data: data)
    }

    private func imageFromFile(_ path: String) -> PlatformImage? {
        guard FileManager.default.fileExists(atPath: path),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path))
        else { return nil }
        return PlatformImage(data: data)
    }

    private func imageFromAsset(_ assetPath: String) -> PlatformImage? {
        // Flutter bundles its assets under App.framework/flutter_assets
        // (inside Contents/…/Resources on macOS).
        #if canImport(UIKit)
        let root = Bundle.main.bundlePath + "/Frameworks/App.framework/flutter_assets/"
        #else
        let root = Bundle.main.bundlePath
            + "/Contents/Frameworks/App.framework/Resources/flutter_assets/"
        #endif
        return imageFromFile(root + assetPath)
    }

    private func imageFromResource(_ reference: String) -> PlatformImage? {
        // resource://[type/]name → use the last path component as the asset name.
        let name = reference.components(separatedBy: "/").last ?? reference
        return PlatformImage(named: name)
    }
    #endif

    private func mediaSource(_ path: String) -> MediaSource {
        let lower = path.lowercased()
        if lower.hasPrefix(MediaSourcePrefix.networkHttp)
            || lower.hasPrefix(MediaSourcePrefix.networkHttps) { return .network }
        if lower.hasPrefix(MediaSourcePrefix.file) { return .file }
        if lower.hasPrefix(MediaSourcePrefix.resource) { return .resource }
        if lower.hasPrefix(MediaSourcePrefix.asset) { return .asset }
        return .unknown
    }

    /// Strips the scheme prefix (network URLs are kept whole).
    private func clean(_ path: String) -> String {
        let lower = path.lowercased()
        if lower.hasPrefix(MediaSourcePrefix.http) { return path }
        if lower.hasPrefix(MediaSourcePrefix.asset) {
            return String(path.dropFirst(MediaSourcePrefix.asset.count))
        }
        if lower.hasPrefix(MediaSourcePrefix.file) {
            return String(path.dropFirst(MediaSourcePrefix.file.count))
        }
        if lower.hasPrefix(MediaSourcePrefix.resource) {
            return String(path.dropFirst(MediaSourcePrefix.resource.count))
        }
        return path
    }
}

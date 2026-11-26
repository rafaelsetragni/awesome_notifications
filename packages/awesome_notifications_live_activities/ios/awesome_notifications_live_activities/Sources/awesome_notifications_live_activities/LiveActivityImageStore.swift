import Foundation
import CoreGraphics
import IosAwnCore
#if canImport(AwesomeNotificationsLiveActivitiesWidget)
import AwesomeNotificationsLiveActivitiesWidget
#endif
#if canImport(UIKit)
import UIKit
#endif

/// Copies the images of the activities (`asset://`, `https://`, `file://`,
/// `resource://`, as the core resolves them) into the App Group container,
/// where the Widget Extension reads them. The App Group comes from the app's
/// Info.plist (`AwnLiveActivitiesAppGroup`); without it the activities show
/// no images.
public final class LiveActivityImageStore {

    public static let shared = LiveActivityImageStore()

    /// The largest side of a stored image, in pixels (ActivityKit drops large
    /// images).
    static let maxPixels: CGFloat = 256
    /// The small copy, for the compact and minimal Dynamic Island.
    static let smallPixels: CGFloat = 72

    public let appGroup: String?
    private var warned = false

    public init(appGroup: String? = Bundle.main.object(forInfoDictionaryKey: LiveActivityKeys.appGroupInfoKey) as? String) {
        let group = appGroup?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.appGroup = (group?.isEmpty ?? true) ? nil : group
    }

    /// The file name of [source] in the App Group (nil: no image).
    /// Call off the main thread (downloads).
    public func store(_ source: String?) -> String? {
        guard let source = source, !source.isEmpty else { return nil }
        guard let directory = AwnLiveActivityImages.directory(appGroup: appGroup) else {
            if !warned {
                warned = true
                NSLog("[AwesomeNotificationsLiveActivities] No App Group (Info.plist "
                      + "\(LiveActivityKeys.appGroupInfoKey), shared with the Widget Extension): "
                      + "the live activities show no images.")
            }
            return nil
        }
        let name = LiveActivityNotifications.imageFileName(source)
        let file = directory.appendingPathComponent(name)
        let smallFile = directory.appendingPathComponent(AwnLiveActivityImages.smallName(name) ?? name)
        // Stored once per reference (an update reuses it, without downloading).
        if FileManager.default.fileExists(atPath: file.path),
           FileManager.default.fileExists(atPath: smallFile.path) { return name }
        #if canImport(UIKit)
        guard let image = LiveActivityImageStore.load(source),
              let data = LiveActivityImageStore.scaled(image, to: LiveActivityImageStore.maxPixels).pngData(),
              let small = LiveActivityImageStore.scaled(image, to: LiveActivityImageStore.smallPixels).pngData()
        else { return nil }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: file, options: .atomic)
            try small.write(to: smallFile, options: .atomic)
            return name
        } catch {
            NSLog("[AwesomeNotificationsLiveActivities] Can't write \(source) to the App Group: \(error)")
            return nil
        }
        #else
        return nil
        #endif
    }

    #if canImport(UIKit)
    /// The image of a reference: network ones with a short timeout (an
    /// activity waits for its images), the others as the core loads them.
    static func load(_ source: String) -> UIImage? {
        guard source.lowercased().hasPrefix("http") else { return BitmapUtils.shared.getBitmapFromSource(source) }
        guard let url = URL(string: source) else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        let done = DispatchSemaphore(value: 0)
        var data: Data?
        URLSession.shared.dataTask(with: request) { body, response, _ in
            if let status = (response as? HTTPURLResponse)?.statusCode, (200..<300).contains(status) { data = body }
            done.signal()
        }.resume()
        _ = done.wait(timeout: .now() + 12)
        return data.flatMap { UIImage(data: $0) }
    }

    static func scaled(_ image: UIImage, to maxPixels: CGFloat) -> UIImage {
        let size = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        let largest = max(size.width, size.height)
        guard largest > maxPixels else { return image }
        let factor = maxPixels / largest
        let target = CGSize(width: (size.width * factor).rounded(), height: (size.height * factor).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
    #endif
}

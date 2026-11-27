import XCTest
import UserNotifications
@testable import IosAwnCore
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The four media sources (`http(s)://`, `file://`, `asset://`, `resource://`)
/// for images and sounds, with the 0.12 fallbacks.
final class MediaSourceTests: XCTestCase {

    private let bitmaps = BitmapUtils.shared
    private let audio = AudioUtils.shared

    private func tempFile(_ ext: String, _ data: Data) throws -> String {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString + "." + ext)
        try data.write(to: url)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url.path
    }

    // MARK: - Images

    func testImageSources() throws {
        XCTAssertNil(bitmaps.getBitmapFromSource(nil))
        XCTAssertNil(bitmaps.getBitmapFromSource(""))
        XCTAssertNil(bitmaps.getBitmapFromSource("ftp://host/image.png"), "unknown scheme")
        XCTAssertNil(bitmaps.getBitmapFromSource("image.png"), "no scheme")

        // A file that exists but is not an image.
        let notAnImage = try tempFile("png", Data("text".utf8))
        XCTAssertNil(bitmaps.getBitmapFromSource("file://" + notAnImage))
    }

    func testANetworkImageThatCannotBeFetchedIsNil() {
        // Nothing listens on port 1: the fetch fails at once.
        XCTAssertNil(bitmaps.getBitmapFromSource("http://127.0.0.1:1/image.png"))
        XCTAssertNil(bitmaps.getBitmapFromSource("HTTPS://127.0.0.1:1/image.png"))
    }

    func testAnAssetOutsideAFlutterAppIsNil() {
        // The test process is no Flutter app: there is no flutter_assets folder.
        XCTAssertNil(bitmaps.getBitmapFromSource("asset://images/logo.png"))
        XCTAssertNil(bitmaps.getBitmapFromSource("Asset://images/logo.png"))
    }

    #if os(macOS)
    func testAResourceIsLoadedByItsLastPathComponent() {
        // A named image every macOS process has.
        XCTAssertNotNil(bitmaps.getBitmapFromSource("resource://drawable/" + NSImage.computerName))
        XCTAssertNotNil(bitmaps.getBitmapFromSource("RESOURCE://" + NSImage.computerName))
        XCTAssertNil(bitmaps.getBitmapFromSource("resource://drawable/no_such_image"))
    }
    #endif

    // MARK: - Sounds

    func testSoundWithoutASourceIsNone() {
        XCTAssertNil(audio.getSoundFromSource(nil))
        XCTAssertNil(audio.getSoundFromSource(""))
        XCTAssertNil(audio.getSoundFromSource("   "))
        XCTAssertNil(audio.getSoundFromSource("sound.aiff"), "unknown scheme")
    }

    func testAnExistingSoundFileIsPlayedByItsPath() throws {
        let path = try tempFile("aiff", Data([0, 1, 2]))
        XCTAssertEqual(audio.getSoundFromSource("file://" + path),
                       UNNotificationSound(named: UNNotificationSoundName(rawValue: path)))
        XCTAssertEqual(audio.getSoundFromSource("FILE://" + path),
                       UNNotificationSound(named: UNNotificationSoundName(rawValue: path)))
        XCTAssertNil(audio.getSoundFromSource("file://"), "a file reference without a path")
    }

    func testNetworkSounds() {
        XCTAssertEqual(audio.getSoundFromSource("http://host/a.mp3"), UNNotificationSound.default)
        XCTAssertNil(audio.getSoundFromSource("https://"), "a URL without a host")
    }

    func testAssetAndResourceSoundsFallBackToTheDefault() {
        // No flutter_assets / bundled .aiff in a test process: 0.12 plays the default.
        XCTAssertEqual(audio.getSoundFromSource("asset://sounds/bell.aiff"), UNNotificationSound.default)
        XCTAssertNil(audio.getSoundFromSource("asset://"), "an asset reference without a path")
        XCTAssertEqual(audio.getSoundFromSource("resource://raw/bell"), UNNotificationSound.default)
        XCTAssertEqual(audio.getSoundFromSource("resource://bell"), UNNotificationSound.default)
    }
}

/// Builder and permission paths the other suites leave out.
final class BuilderEdgeCaseTests: XCTestCase {

    private let builder = NotificationBuilder.newInstance()

    override func setUp() {
        super.setUp()
        ChannelManager.shared.clearForTest()
        CriticalAlertUtils.clearCache()
    }

    override func tearDown() {
        ChannelManager.shared.clearForTest()
        CriticalAlertUtils.clearCache()
        super.tearDown()
    }

    func testBuildWithoutAnIdIsNoNotification() throws {
        XCTAssertNil(try builder.build(model: [Definitions.NOTIFICATION_CONTENT: [
            Definitions.NOTIFICATION_TITLE: "No id"]]))
    }

    func testACalendarTriggerIsDisplayedAtItsNextFireDateWhileTerminated() throws {
        var components = DateComponents()
        components.hour = 10
        components.minute = 30
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let built = try XCTUnwrap(builder.build(model: [Definitions.NOTIFICATION_CONTENT: [
            Definitions.NOTIFICATION_ID: 5]]))
        let scheduled = builder.stampDisplayed(on: BuiltNotification(
            id: built.id, content: built.content, trigger: trigger, model: built.model))

        let content = builder.contentMap(fromModel: scheduled.model)
        XCTAssertEqual(content[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String, "Terminated")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        XCTAssertEqual(content[Definitions.NOTIFICATION_DISPLAYED_DATE] as? String,
                       formatter.string(from: trigger.nextTriggerDate()!))
        // The stored payload carries it too.
        let stored = builder.contentMap(fromModel: builder.notificationModel(
            fromUserInfo: scheduled.content.userInfo)!)
        XCTAssertEqual(stored[Definitions.NOTIFICATION_DISPLAYED_LIFECYCLE] as? String, "Terminated")
    }

    func testACriticalChannelPlaysTheCustomSoundThenTheChannelSound() throws {
        CriticalAlertUtils.setCache(true)
        ChannelManager.shared.setChannel([
            Definitions.NOTIFICATION_CHANNEL_KEY: "critical",
            Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS: true,
            Definitions.NOTIFICATION_SOUND_SOURCE: "https://host/channel.mp3"
        ])
        func sound(_ extra: [String: Any]) -> UNNotificationSound? {
            var content: [String: Any] = [Definitions.NOTIFICATION_ID: 1,
                                          Definitions.NOTIFICATION_CHANNEL_KEY: "critical"]
            for (key, value) in extra { content[key] = value }
            return builder.createNotificationContent(
                fromModel: [Definitions.NOTIFICATION_CONTENT: content])?.content.sound
        }
        // The custom sound wins (an unknown scheme resolves to no sound).
        XCTAssertNil(sound([Definitions.NOTIFICATION_CUSTOM_SOUND: "bell.aiff"]))
        XCTAssertEqual(sound([Definitions.NOTIFICATION_CUSTOM_SOUND: "https://host/custom.mp3"]),
                       UNNotificationSound.default)
        // Without one, the channel's source (a network sound plays the default).
        XCTAssertEqual(sound([:]), UNNotificationSound.default)
        XCTAssertNotEqual(sound([:]), UNNotificationSound.defaultCritical)
    }

    func testChannelLevelPermissionSwitches() {
        let manager = PermissionManager.shared
        ChannelManager.shared.setChannel([Definitions.NOTIFICATION_CHANNEL_KEY: "plain"])
        XCTAssertFalse(manager.isSpecifiedChannelPermissionAllowed(channelKey: "plain", permission: .alert),
                       "Default importance shows no alert")
        XCTAssertTrue(manager.isSpecifiedChannelPermissionAllowed(channelKey: "plain", permission: .sound))
        XCTAssertFalse(manager.isSpecifiedChannelPermissionAllowed(channelKey: "plain", permission: .badge))
        XCTAssertFalse(manager.isSpecifiedChannelPermissionAllowed(channelKey: "plain", permission: .criticalAlert))
        XCTAssertTrue(manager.isSpecifiedChannelPermissionAllowed(channelKey: "plain", permission: .car))

        ChannelManager.shared.setChannel([
            Definitions.NOTIFICATION_CHANNEL_KEY: "loud",
            Definitions.NOTIFICATION_IMPORTANCE: "High",
            Definitions.NOTIFICATION_PLAY_SOUND: false,
            Definitions.NOTIFICATION_CHANNEL_SHOW_BADGE: true,
            Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS: true
        ])
        XCTAssertTrue(manager.isSpecifiedChannelPermissionAllowed(channelKey: "loud", permission: .alert))
        XCTAssertFalse(manager.isSpecifiedChannelPermissionAllowed(channelKey: "loud", permission: .sound))
        XCTAssertTrue(manager.isSpecifiedChannelPermissionAllowed(channelKey: "loud", permission: .badge))
        XCTAssertTrue(manager.isSpecifiedChannelPermissionAllowed(channelKey: "loud", permission: .criticalAlert))

        ChannelManager.shared.setChannel([
            Definitions.NOTIFICATION_CHANNEL_KEY: "max", Definitions.NOTIFICATION_IMPORTANCE: "Max"])
        XCTAssertTrue(manager.isSpecifiedChannelPermissionAllowed(channelKey: "max", permission: .alert))
    }
}

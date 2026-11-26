import XCTest
import UserNotifications
@testable import IosAwnCore

/// 0.12.1 importance / wakeUpScreen / critical-alert rules: the interruption
/// level and sound the builder sets from the content and its channel.
final class InterruptionLevelTests: XCTestCase {

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

    private func channel(
        importance: String? = nil, critical: Bool? = nil,
        playSound: Bool? = nil, soundSource: String? = nil
    ) {
        var map: [String: Any] = [Definitions.NOTIFICATION_CHANNEL_KEY: "test"]
        if let importance = importance { map[Definitions.NOTIFICATION_IMPORTANCE] = importance }
        if let critical = critical { map[Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS] = critical }
        if let playSound = playSound { map[Definitions.NOTIFICATION_PLAY_SOUND] = playSound }
        if let soundSource = soundSource { map[Definitions.NOTIFICATION_SOUND_SOURCE] = soundSource }
        ChannelManager.shared.setChannel(map)
    }

    private func build(_ extra: [String: Any] = [:], channelKey: String = "test") -> UNMutableNotificationContent? {
        var content: [String: Any] = [
            Definitions.NOTIFICATION_ID: 1,
            Definitions.NOTIFICATION_CHANNEL_KEY: channelKey,
            Definitions.NOTIFICATION_TITLE: "T"
        ]
        for (key, value) in extra { content[key] = value }
        return builder.createNotificationContent(
            fromModel: [Definitions.NOTIFICATION_CONTENT: content])?.content
    }

    // MARK: - Interruption level

    func testInterruptionLevelMatrix() throws {
        guard #available(iOS 15.0, macOS 12.0, *) else { throw XCTSkip("needs iOS 15 / macOS 12") }
        for wakeUp in [false, true] {
            for critical in [false, true] {
                for available in [false, true] {
                    channel(importance: "Default", critical: critical)
                    CriticalAlertUtils.setCache(available)
                    let level = build([Definitions.NOTIFICATION_WAKE_UP_SCREEN: wakeUp])?.interruptionLevel
                    let expected: UNNotificationInterruptionLevel =
                        (critical && available) ? .critical : (wakeUp ? .timeSensitive : .active)
                    XCTAssertEqual(level, expected,
                                   "wakeUpScreen \(wakeUp), critical channel \(critical), available \(available)")
                }
            }
        }
    }

    func testImportanceSetsTheLevel() throws {
        guard #available(iOS 15.0, macOS 12.0, *) else { throw XCTSkip("needs iOS 15 / macOS 12") }
        let expected: [String: UNNotificationInterruptionLevel] = [
            "None": .passive, "Min": .passive, "Low": .passive,
            "Default": .active, "High": .timeSensitive, "Max": .timeSensitive
        ]
        for (importance, level) in expected {
            channel(importance: importance)
            XCTAssertEqual(build()?.interruptionLevel, level, importance)
        }
        // Without importance, an unknown one, or an unregistered channel: Default.
        channel()
        XCTAssertEqual(build()?.interruptionLevel, .active)
        channel(importance: "Urgent")
        XCTAssertEqual(build()?.interruptionLevel, .active)
        XCTAssertEqual(build(channelKey: "unknown")?.interruptionLevel, .active)
    }

    func testWakeUpScreenRaisesALowImportance() throws {
        guard #available(iOS 15.0, macOS 12.0, *) else { throw XCTSkip("needs iOS 15 / macOS 12") }
        channel(importance: "Low")
        XCTAssertEqual(build([Definitions.NOTIFICATION_WAKE_UP_SCREEN: true])?.interruptionLevel,
                       .timeSensitive)
    }

    /// 0.12.1: critical is channel-only — a `criticalAlert` content key is ignored.
    func testCriticalAlertContentKeyIsIgnored() throws {
        guard #available(iOS 15.0, macOS 12.0, *) else { throw XCTSkip("needs iOS 15 / macOS 12") }
        channel(importance: "Default", critical: false)
        CriticalAlertUtils.setCache(true)
        XCTAssertEqual(build(["criticalAlert": true])?.interruptionLevel, .active)
    }

    func testAvailabilityIsACacheReadDefaultingToFalse() {
        XCTAssertFalse(CriticalAlertUtils.canDeliverCriticalAlerts())
        CriticalAlertUtils.setCache(true)
        XCTAssertTrue(CriticalAlertUtils.canDeliverCriticalAlerts())
        CriticalAlertUtils.clearCache()
        XCTAssertFalse(CriticalAlertUtils.canDeliverCriticalAlerts())
    }

    func testEnsureAvailabilityRunsAtOnceWhenCached() {
        CriticalAlertUtils.setCache(false)
        var ran = false
        CriticalAlertUtils.ensureAvailabilityResolved { ran = true }
        XCTAssertTrue(ran)
    }

    func testCriticalIsRequestedOnlyByTheChannel() {
        XCTAssertFalse(CriticalAlertUtils.isCriticalAlertRequested(channel: nil))
        XCTAssertFalse(CriticalAlertUtils.isCriticalAlertRequested(channel: [:]))
        XCTAssertFalse(CriticalAlertUtils.isCriticalAlertRequested(
            channel: [Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS: NSNull()]))
        XCTAssertTrue(CriticalAlertUtils.isCriticalAlertRequested(
            channel: [Definitions.NOTIFICATION_CHANNEL_CRITICAL_ALERTS: true]))
    }

    // MARK: - Sound

    func testCriticalChannelPlaysTheDefaultCriticalSound() {
        channel(critical: true)
        CriticalAlertUtils.setCache(true)
        XCTAssertEqual(build()?.sound, UNNotificationSound.defaultCritical)
    }

    func testCriticalChannelWithoutAvailabilityPlaysTheDefaultSound() {
        channel(critical: true)
        CriticalAlertUtils.setCache(false)
        XCTAssertEqual(build()?.sound, UNNotificationSound.default)
    }

    /// 0.12.1 quirk: a critical channel ignores the importance for the sound —
    /// even a Low one plays the critical sound.
    func testCriticalSoundIgnoresTheImportance() {
        channel(importance: "Low", critical: true)
        CriticalAlertUtils.setCache(true)
        XCTAssertEqual(build()?.sound, UNNotificationSound.defaultCritical)
    }

    func testSoundTurnedOffIsSilentEvenWhenCritical() {
        CriticalAlertUtils.setCache(true)
        channel(critical: true, playSound: false)
        XCTAssertNil(build()?.sound)
        channel(critical: true)
        XCTAssertNil(build([Definitions.NOTIFICATION_PLAY_SOUND: false])?.sound)
        channel(critical: false)
        XCTAssertNil(build([Definitions.NOTIFICATION_PLAY_SOUND: false])?.sound)
    }

    func testLowImportancesPlayNoSound() {
        for importance in ["None", "Min", "Low"] {
            channel(importance: importance)
            XCTAssertNil(build()?.sound, importance)
        }
        for importance in ["Default", "High", "Max"] {
            channel(importance: importance)
            XCTAssertEqual(build()?.sound, UNNotificationSound.default, importance)
        }
    }

    func testCustomSoundSources() {
        channel()
        // A network sound is never downloaded: the default sound.
        XCTAssertEqual(build([Definitions.NOTIFICATION_CUSTOM_SOUND: "https://x.com/a.mp3"])?.sound,
                       UNNotificationSound.default)
        // A missing file falls back to the default sound.
        XCTAssertEqual(build([Definitions.NOTIFICATION_CUSTOM_SOUND: "file:///nope/a.aiff"])?.sound,
                       UNNotificationSound.default)
        // An unknown scheme is no sound.
        XCTAssertNil(build([Definitions.NOTIFICATION_CUSTOM_SOUND: "sound.aiff"])?.sound)
        // The channel's source applies without a custom sound.
        channel(soundSource: "https://x.com/b.mp3")
        XCTAssertEqual(build()?.sound, UNNotificationSound.default)
    }
}

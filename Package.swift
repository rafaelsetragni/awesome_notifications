// swift-tools-version: 5.9
// Apple-side native engine of the Awesome Notifications monorepo.
//
// This Package.swift lives at the repo ROOT on purpose: Swift Package Manager only
// resolves a Package.swift at the root of a referenced repository, so keeping it here
// lets a consumer's Notification Service Extension import the core by URL + tag.
// The actual sources live under native/apple/ (targets point to them via `path:`).

import PackageDescription

let package = Package(
    name: "AwesomeNotifications",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        // One product per capability (Core first; Fcm and others come later as decorators).
        .library(name: "IosAwnCore", targets: ["IosAwnCore"])
    ],
    targets: [
        .target(
            name: "IosAwnCore",
            path: "native/apple/Sources/IosAwnCore"
        ),
        .testTarget(
            name: "IosAwnCoreTests",
            dependencies: ["IosAwnCore"],
            path: "native/apple/Tests/IosAwnCoreTests"
        ),

        // Decorator logic exposed for unit testing. Each add-on's Flutter-free
        // Swift compiles here (the plugin file that imports Flutter is excluded),
        // so `swift test` can run their tests from the CLI without the Flutter
        // engine. These are not vended as products — they exist only for tests.
        .target(
            name: "SchedulesLogic",
            dependencies: ["IosAwnCore"],
            path: "packages/awesome_notifications_schedules/ios/awesome_notifications_schedules/Sources/awesome_notifications_schedules",
            exclude: ["AwesomeNotificationsSchedulesPlugin.swift"]
        ),
        .testTarget(
            name: "SchedulesLogicTests",
            dependencies: ["SchedulesLogic"],
            path: "native/apple/Tests/SchedulesLogicTests"
        ),
        .target(
            name: "LocalizationsLogic",
            dependencies: ["IosAwnCore"],
            path: "packages/awesome_notifications_localizations/ios/awesome_notifications_localizations/Sources/awesome_notifications_localizations",
            exclude: ["AwesomeNotificationsLocalizationsPlugin.swift"]
        ),
        .testTarget(
            name: "LocalizationsLogicTests",
            dependencies: ["LocalizationsLogic"],
            path: "native/apple/Tests/LocalizationsLogicTests"
        ),
        .target(
            name: "FcmLogic",
            dependencies: ["IosAwnCore"],
            path: "packages/awesome_notifications_fcm/ios/awesome_notifications_fcm/Sources/awesome_notifications_fcm",
            exclude: ["AwesomeNotificationsFcmPlugin.swift", "DartFcmBackgroundExecutor.swift"]
        ),
        .target(
            name: "ChatLogic",
            dependencies: ["IosAwnCore"],
            path: "packages/awesome_notifications_chat/ios/awesome_notifications_chat/Sources/awesome_notifications_chat",
            exclude: ["AwesomeNotificationsChatPlugin.swift", "PrivacyInfo.xcprivacy"]
        ),
        .testTarget(
            name: "ChatLogicTests",
            dependencies: ["ChatLogic"],
            path: "native/apple/Tests/ChatLogicTests"
        ),
        // The service-extension products of the add-ons (symlinks to their
        // Flutter-free sources), compiled here so `swift build` checks them.
        .target(
            name: "AwesomeNotificationsFcmExtension",
            dependencies: ["IosAwnCore"],
            path: "packages/awesome_notifications_fcm/ios/awesome_notifications_fcm/Sources/AwesomeNotificationsFcmExtension"
        ),
        .target(
            name: "AwesomeNotificationsChatExtension",
            dependencies: ["IosAwnCore"],
            path: "packages/awesome_notifications_chat/ios/awesome_notifications_chat/Sources/AwesomeNotificationsChatExtension"
        ),
        .testTarget(
            name: "ServiceExtensionTests",
            dependencies: ["AwesomeNotificationsFcmExtension", "AwesomeNotificationsChatExtension"],
            path: "native/apple/Tests/ServiceExtensionTests"
        ),
        .testTarget(
            name: "FcmLogicTests",
            dependencies: ["FcmLogic"],
            path: "native/apple/Tests/FcmLogicTests"
        )
    ]
)

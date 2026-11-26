// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "awesome_notifications_live_activities",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "awesome-notifications-live-activities", targets: ["awesome_notifications_live_activities"])
    ],
    dependencies: [
        // The base plugin vends the shared IosAwnCore engine + builder registry.
        // The sibling path resolves from Flutter's ephemeral .packages layout.
        .package(name: "awesome_notifications", path: "../awesome_notifications"),
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // The widget's package, inside this one (no dependencies: the app's
        // Widget Extension links it too).
        .package(name: "AwesomeNotificationsLiveActivitiesWidget", path: "AwesomeNotificationsLiveActivitiesWidget")
    ],
    targets: [
        .target(
            name: "awesome_notifications_live_activities",
            dependencies: [
                .product(name: "AwesomeNotificationsLiveActivitiesWidget", package: "AwesomeNotificationsLiveActivitiesWidget"),
                .product(name: "IosAwnCore", package: "awesome_notifications"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)

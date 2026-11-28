// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "awesome_notifications_fcm",
    platforms: [
        // firebase_core 5 (Firebase 13) requires macOS 11 for Swift packages.
        .macOS("11.0")
    ],
    products: [
        .library(name: "awesome-notifications-fcm", targets: ["awesome_notifications_fcm"])
    ],
    dependencies: [
        // The base plugin vends the shared IosAwnCore engine + registries.
        // The sibling path resolves from Flutter's ephemeral .packages layout.
        .package(name: "awesome_notifications", path: "../awesome_notifications"),
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // Same firebase-ios-sdk line as iOS (and as the firebase_core plugin).
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", "13.0.0"..<"14.0.0")
    ],
    targets: [
        .target(
            name: "awesome_notifications_fcm",
            dependencies: [
                .product(name: "IosAwnCore", package: "awesome_notifications"),
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)

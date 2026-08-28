// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "awesome_notifications_fcm",
    platforms: [
        // Firebase Messaging requires a modern deployment target.
        .iOS("15.0")
    ],
    products: [
        .library(name: "awesome-notifications-fcm", targets: ["awesome_notifications_fcm"])
    ],
    dependencies: [
        // Depend on the base plugin package and use its vended IosAwnCore product,
        // so pushes are displayed through the very same IosAwnCore engine +
        // decorator registries the base plugin uses. The sibling path resolves
        // from Flutter's ios/Flutter/ephemeral/Packages/.packages layout.
        .package(name: "awesome_notifications", path: "../awesome_notifications"),
        // Firebase Cloud Messaging. Kept on the 12.x line so it resolves to the
        // same firebase-ios-sdk the firebase_core Flutter plugin pulls in.
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", "12.0.0"..<"13.0.0")
    ],
    targets: [
        .target(
            name: "awesome_notifications_fcm",
            dependencies: [
                .product(name: "IosAwnCore", package: "awesome_notifications"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")
            ]
        )
    ]
)

// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "awesome_notifications_chat",
    platforms: [
        .macOS("12.0")
    ],
    products: [
        .library(name: "awesome-notifications-chat", targets: ["awesome_notifications_chat"])
    ],
    dependencies: [
        // The base plugin vends the shared IosAwnCore engine + builder registry.
        // The sibling path resolves from Flutter's ephemeral .packages layout.
        .package(name: "awesome_notifications", path: "../awesome_notifications"),
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "awesome_notifications_chat",
            dependencies: [
                .product(name: "IosAwnCore", package: "awesome_notifications"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)

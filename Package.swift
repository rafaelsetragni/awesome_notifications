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
        )
    ]
)

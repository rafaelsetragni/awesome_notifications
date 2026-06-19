// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "awesome_notifications",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "awesome-notifications", targets: ["awesome_notifications"])
    ],
    dependencies: [],
    targets: [
        // Flutter-free Apple engine. The sources live once at the repo root under
        // native/apple/Sources/IosAwnCore and are exposed here through the
        // Sources/IosAwnCore symlink. A cross-package `.package(path:)` cannot be
        // used because Flutter's generated SPM package references this plugin
        // through a symlink, which breaks relative dependency paths; symlinked
        // target *sources* are resolved by the filesystem and work correctly.
        .target(
            name: "IosAwnCore",
            path: "Sources/IosAwnCore"
        ),
        .target(
            name: "awesome_notifications",
            dependencies: ["IosAwnCore"],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)

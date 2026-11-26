// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "awesome_notifications",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "awesome-notifications", targets: ["awesome_notifications"]),
        // The core is also vended as a product so decorator add-on plugins
        // (e.g. awesome_notifications_localizations) can depend on THIS package
        // and share the exact same compiled IosAwnCore — its singletons (event
        // bus, decorator registries) must be one instance across the plugins.
        .library(name: "IosAwnCore", targets: ["IosAwnCore"])
    ],
    dependencies: [],
    targets: [
        // Flutter-free Apple engine. The sources live once at the repo root under
        // native/apple/Sources/IosAwnCore and are exposed here through the
        // Sources/IosAwnCore symlink. A cross-package `.package(path:)` to the
        // repo root cannot be used: Flutter resolves a plugin's relative
        // dependency paths from its `.packages/<name>` symlink (under
        // ios/Flutter/ephemeral/Packages/.packages), so `../../../../` escapes to
        // ios/Flutter and fails. Symlinked target *sources* are resolved by the
        // filesystem and work; add-ons reach this core via the sibling
        // `../awesome_notifications` path (which stays inside `.packages`).
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

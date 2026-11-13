// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "awesome_notifications",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "awesome-notifications", targets: ["awesome_notifications"]),
        // The shared Apple engine, vended so decorators can display through it.
        .library(name: "IosAwnCore", targets: ["IosAwnCore"])
    ],
    dependencies: [
        // Flutter's SPM integration vends the engine as a local package.
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        // Sources/IosAwnCore is a symlink to the repo-root native/apple engine
        // (single source shared with iOS). A cross-package `.package(path:)`
        // would break under Flutter's symlinked plugin layout; symlinked target
        // sources resolve from their real location.
        .target(
            name: "IosAwnCore",
            path: "Sources/IosAwnCore"
        ),
        .target(
            name: "awesome_notifications",
            dependencies: [
                "IosAwnCore",
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)

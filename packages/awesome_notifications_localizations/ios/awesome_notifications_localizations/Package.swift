// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "awesome_notifications_localizations",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "awesome-notifications-localizations", targets: ["awesome_notifications_localizations"])
    ],
    dependencies: [
        // Depend on the base plugin package and use its vended IosAwnCore product,
        // so this decorator registers its transformer/handler into the very same
        // IosAwnCore singletons the base plugin's engine reads from.
        //
        // Flutter lays every plugin out as a sibling under
        // ios/Flutter/ephemeral/Packages/.packages/<name>, and resolves a plugin's
        // relative dependency paths from THAT symlink location — so the sibling
        // path `../awesome_notifications` reaches the base plugin correctly
        // (whereas a path that climbs out of `.packages` would not).
        .package(name: "awesome_notifications", path: "../awesome_notifications")
    ],
    targets: [
        .target(
            name: "awesome_notifications_localizations",
            dependencies: [
                .product(name: "IosAwnCore", package: "awesome_notifications")
            ]
        )
    ]
)

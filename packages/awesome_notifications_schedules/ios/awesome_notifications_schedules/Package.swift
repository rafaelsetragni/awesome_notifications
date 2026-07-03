// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "awesome_notifications_schedules",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "awesome-notifications-schedules", targets: ["awesome_notifications_schedules"])
    ],
    dependencies: [
        // Depend on the base plugin package and use its vended IosAwnCore product,
        // so this decorator registers its schedule provider into the very same
        // IosAwnCore singletons the base plugin's engine reads from. The sibling
        // path resolves from Flutter's ios/Flutter/ephemeral/Packages/.packages
        // layout (see the localizations decorator for the same pattern).
        .package(name: "awesome_notifications", path: "../awesome_notifications")
    ],
    targets: [
        .target(
            name: "awesome_notifications_schedules",
            dependencies: [
                .product(name: "IosAwnCore", package: "awesome_notifications")
            ]
        )
    ]
)

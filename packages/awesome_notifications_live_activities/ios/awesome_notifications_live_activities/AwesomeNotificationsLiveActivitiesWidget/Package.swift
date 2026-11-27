// swift-tools-version: 5.9
// The part of awesome_notifications_live_activities the app's Widget Extension
// links: the activity's attributes, the widget that draws it and its buttons'
// intent. A package of its own, with no dependencies, so the extension resolves
// it without Flutter or the core (the plugin depends on it too).

import PackageDescription

let package = Package(
    name: "AwesomeNotificationsLiveActivitiesWidget",
    platforms: [
        .iOS("15.0"),
        .macOS("12.0")
    ],
    products: [
        .library(name: "AwesomeNotificationsLiveActivitiesWidget", targets: ["AwesomeNotificationsLiveActivitiesWidget"])
    ],
    targets: [
        .target(name: "AwesomeNotificationsLiveActivitiesWidget")
    ]
)

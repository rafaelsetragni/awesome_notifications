public enum NotificationPermissionStatus : String, CaseIterable {
    case granted = "granted"
    case denied = "denied"
    case notDetermined = "notDetermined"
    case notSupported = "notSupported"

    static func fromString(_ label: String) -> NotificationPermissionStatus? {
        return self.allCases.first { "\($0)" == label }
    }
}

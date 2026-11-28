import Foundation

/// An error a channel method answers with instead of a value. Flutter-free: the
/// plugin bridges turn it into a `FlutterError(code:message:details:)`, so Dart
/// sees the same `PlatformException` the 0.12 plugin threw. A builder decorator
/// throws it to reject a notification (e.g. an invalid schedule), and a method
/// handler passes it to `result` to fail a call.
public struct AwesomeNotificationsException: Error {
    public let code: String
    public let message: String
    public let detailedCode: String

    public init(code: String, message: String, detailedCode: String) {
        self.code = code
        self.message = message
        self.detailedCode = detailedCode
    }

    /// 0.12's `ExceptionCode.CODE_INVALID_ARGUMENTS`.
    public static let CODE_INVALID_ARGUMENTS = "INVALID_ARGUMENTS"
    /// 0.12's `ExceptionCode.CODE_MISSING_ARGUMENTS`.
    public static let CODE_MISSING_ARGUMENTS = "MISSING_ARGUMENTS"
    /// 0.12's `ExceptionCode.DETAILED_REQUIRED_ARGUMENTS`.
    public static let DETAILED_REQUIRED_ARGUMENTS = "arguments.required"
    /// 0.12's `ExceptionCode.DETAILED_INVALID_ARGUMENTS`.
    public static let DETAILED_INVALID_ARGUMENTS = "arguments.invalid"
}

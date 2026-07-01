import Foundation
import IosAwnCore

/// Answers the core's setLocalization/getLocalization channel methods, delegated
/// by the base plugin's bridge through the AwesomeMethodHandlerRegistry seam.
final class LocalizationMethodHandler: AwesomeMethodHandler {
    func handle(
        method: String,
        arguments: Any?,
        result: @escaping (Any?) -> Void
    ) -> Bool {
        switch method {
        case "setLocalization":
            result(LocalizationManager.shared.setLocalization(arguments as? String))
            return true
        case "getLocalization":
            result(LocalizationManager.shared.getLocalization())
            return true
        default:
            return false
        }
    }
}

import Foundation
import IosAwnCore

/// Builder decorator that **translates** a notification before it is built. It
/// inherits the core `NotificationBuilder`, overrides `build`, runs the
/// `LocalizationTransformer` over the model (title/body/summary/images and button
/// labels for the current language), then delegates the actual content building to
/// the wrapped builder via `next`. Without a `localizations` block it just passes
/// the model through unchanged.
///
/// Registered with a HIGH priority so it ends up outermost — translation happens
/// before lower-priority decorators (e.g. scheduling) see the model.
final class LocalizationBuilder: NotificationBuilder {

    private let transformer = LocalizationTransformer()

    override func build(model: [String: Any]) -> BuiltNotification? {
        return next(transformer.transform(model))
    }
}

import XCTest
@testable import IosAwnCore

/// The builder decorator chain must compose in ascending priority order.
final class NotificationBuilderRegistryTests: XCTestCase {

    override func setUp() {
        super.setUp()
        NotificationBuilderRegistry.shared.clearForTest()
    }

    override func tearDown() {
        NotificationBuilderRegistry.shared.clearForTest()
        super.tearDown()
    }

    func testComposesInAscendingPriority() {
        var order: [Int] = []
        // Register out of order; the fold must apply them low → high priority.
        NotificationBuilderRegistry.shared.register(priority: 100) { inner in
            order.append(100); return inner
        }
        NotificationBuilderRegistry.shared.register(priority: 10) { inner in
            order.append(10); return inner
        }
        NotificationBuilderRegistry.shared.register(priority: 50) { inner in
            order.append(50); return inner
        }

        _ = NotificationBuilderRegistry.shared.makeBuilder()

        XCTAssertEqual(order, [10, 50, 100])
    }

    func testRegisteredDecoratorParticipatesInBuild() {
        var decoratorRan = false
        NotificationBuilderRegistry.shared.register(priority: 10) { inner in
            RecordingBuilder(inner: inner) { decoratorRan = true }
        }
        let builder = NotificationBuilderRegistry.shared.makeBuilder()

        _ = builder.build(model: [
            Definitions.NOTIFICATION_CONTENT: [Definitions.NOTIFICATION_ID: 1]
        ])

        XCTAssertTrue(decoratorRan)
    }
}

/// A decorator that records when its build runs, then delegates.
private final class RecordingBuilder: NotificationBuilder {
    private let onBuild: () -> Void
    init(inner: NotificationBuilder, onBuild: @escaping () -> Void) {
        self.onBuild = onBuild
        super.init(inner: inner)
    }
    override func build(model: [String: Any]) -> BuiltNotification? {
        onBuild()
        return next(model)
    }
}

import AwesomeNotificationsLiveActivitiesWidget
import SwiftUI
import WidgetKit

/// The app's Live Activities, drawn by awesome_notifications_live_activities.
@main
struct LiveActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        AwnLiveActivityWidget()
    }
}

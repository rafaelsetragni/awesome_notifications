import ActivityKit
import AwesomeNotificationsLiveActivitiesWidget
import SwiftUI
import WidgetKit

/// The app's Live Activities. Most are drawn by awesome_notifications_live_activities;
/// the focus timer (`customLayout: 'focus_timer'`) by the app itself.
///
/// An app that draws none of its own just returns `AwnLiveActivityWidget()`.
@main
struct LiveActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        LiveActivityWidget()
    }
}

struct LiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AwnLiveActivityAttributes.self) { context in
            if context.state.customLayout == "focus_timer" {
                FocusTimerView(context: context)
            } else {
                AwnLiveActivityWidget.lockScreen(context)
            }
        } dynamicIsland: { context in
            // The package's Dynamic Island for every activity.
            AwnLiveActivityWidget.dynamicIsland(context)
        }
    }
}

/// The focus timer: the accent color as a bar, the title and the body, a large
/// countdown the system runs by itself, and the buttons.
struct FocusTimerView: View {
    let context: ActivityViewContext<AwnLiveActivityAttributes>

    var body: some View {
        let state = context.state
        let accent = AwnColors.accent(state)
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 2).fill(accent).frame(width: 4, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.title ?? "").font(.headline)
                    Text(state.body ?? "").font(.subheadline).foregroundColor(.secondary)
                }
                Spacer(minLength: 8)
                if state.ended != true, let timer = AwnTimerText(state: state) {
                    timer.font(.system(size: 40, weight: .medium).monospacedDigit())
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 140, alignment: .trailing)
                }
            }
            AwnButtonsView(attributes: context.attributes, state: state, compact: true)
        }
        .padding(16)
        .activitySystemActionForegroundColor(accent)
    }
}

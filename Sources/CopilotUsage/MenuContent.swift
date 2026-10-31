import AppKit
import CopilotUsageCore
import SwiftUI

struct MenuContent: View {
    let model: UsageModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if let usage = model.usage {
            if usage.unlimited {
                Text("Unlimited premium requests")
            } else {
                Text("Remaining: \(Formatting.count(usage.remaining)) – \(Formatting.percent(usage.percentRemaining))")
            }
            if let resetDate = usage.resetDate {
                Text("Resets: \(Formatting.resetDate(resetDate))")
            }
            if let forecast = model.forecast, usage.remaining > 0 {
                Text("Budget: \(Formatting.count(forecast.dailyBudget))/day until reset")
                if let runOutDate = forecast.runOutDate {
                    Text("Pace: \(Formatting.perDay(forecast.averagePerDay)) · runs out \(Formatting.day(runOutDate))")
                } else {
                    Text("Pace: \(Formatting.perDay(forecast.averagePerDay)) · lasts until reset")
                }
            }
        }

        if !model.history.isEmpty {
            Divider()
            Button(historyLabel) {
                openWindow(id: HistoryView.windowID)
                NSApp.activate()
            }
        }

        if let error = model.error {
            Text(error.message)
        }

        if let lastUpdated = model.lastUpdated {
            Text("Updated: \(lastUpdated.formatted(date: .omitted, time: .shortened))")
        }

        if !model.hasToken {
            Text("No GitHub token set")
        }

        Divider()

        if model.hasToken {
            Button("Refresh Now") {
                Task { await model.refresh() }
            }
            .keyboardShortcut("r")
        }

        Button(model.hasToken ? "Change Token…" : "Set Token…") {
            openWindow(id: TokenView.windowID)
            NSApp.activate()
        }

        if model.hasToken {
            Button("Remove Token") { model.removeToken() }
        }

        Divider()

        Text("CopilotUsage \(appVersion)")

        Button("Quit CopilotUsage") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private var historyLabel: String {
        guard model.history.samples.count > 1 else { return "History…" }
        let days = model.history.daily(days: 14).map(\.used)
        let lastWeek = model.history.used(from: .now.addingTimeInterval(-7 * 86400))
        return "\(Formatting.sparkline(days))  \(Formatting.count(lastWeek)) last 7 days"
    }
}

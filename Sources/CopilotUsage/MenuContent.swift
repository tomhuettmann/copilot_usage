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
        }

        if let error = model.error {
            Text("⚠︎ \(error.message)")
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
}

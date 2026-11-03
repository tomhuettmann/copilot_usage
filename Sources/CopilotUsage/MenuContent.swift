import CopilotUsageCore
import SwiftUI

struct MenuContent: View {
    let model: UsageModel
    @State private var showsSettings = false

    var body: some View {
        Group {
            if !model.hasToken {
                onboarding
            } else if showsSettings {
                SettingsView(model: model) { showsSettings = false }
            } else {
                dashboard
            }
        }
        .padding(12)
        .frame(width: 360, alignment: .leading)
        .onDisappear { showsSettings = false }
    }

    private var dashboard: some View {
        VStack(alignment: .leading, spacing: 14) {
            UsageHeaderView(model: model)

            if let usage = model.usage, !usage.unlimited {
                StatTiles(usage: usage, forecast: model.forecast)
                UsageChartView(model: model)
            }

            FooterBar(model: model) { showsSettings = true }
        }
    }

    private var onboarding: some View {
        VStack(alignment: .leading, spacing: 14) {
            TokenView(model: model) {}
            FooterBar(model: model) {}
        }
    }
}

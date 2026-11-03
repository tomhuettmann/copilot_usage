import CopilotUsageCore
import SwiftUI

struct StatTiles: View {
    let usage: Usage
    let forecast: Forecast?

    var body: some View {
        HStack(spacing: 8) {
            StatTile(title: "Remaining", value: Formatting.count(max(usage.remaining, 0)))
            StatTile(title: "Budget", value: forecast.map { "\(Formatting.count($0.dailyBudget))/day" } ?? "–")
            StatTile(title: "Pace", value: forecast.map { "\(Formatting.count(Int($0.averagePerDay.rounded())))/day" } ?? "–")
        }
    }
}

struct StatTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(title)
                .font(.appMeta)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.appValue)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.06)))
        .accessibilityElement(children: .combine)
    }
}

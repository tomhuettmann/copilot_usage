import CopilotUsageCore
import SwiftUI

struct UsageHeaderView: View {
    let model: UsageModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let usage = model.usage {
                if usage.unlimited {
                    Text("Unlimited premium requests").font(.appTitle)
                } else {
                    statusRow(usage)
                    UsageBar(
                        used: usedFraction(usage),
                        expected: model.forecast?.elapsedFraction,
                        color: model.status?.color ?? .accentColor
                    )
                    Text("\(Formatting.count(usage.used)) / \(Formatting.count(usage.entitlement)) · \(Formatting.percent(100 - usage.percentRemaining)) used")
                        .font(.appBody)
                        .foregroundStyle(.secondary)
                }
            } else if model.error == nil {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text("Loading…").foregroundStyle(.secondary)
                }
            }

            if let error = model.error {
                Text(error.message)
                    .font(.appBody)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusRow(_ usage: Usage) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(model.status?.color ?? .secondary)
                .frame(width: 9, height: 9)
            Text(Formatting.statusLine(for: usage, forecast: model.forecast))
                .font(.appTitle)
        }
    }

    private func usedFraction(_ usage: Usage) -> Double {
        guard usage.entitlement > 0 else { return 0 }
        return min(max(Double(usage.used) / Double(usage.entitlement), 0), 1)
    }
}

/// A progress bar whose tick marks how much of the period has passed.
struct UsageBar: View {
    let used: Double
    let expected: Double?
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.12))
                Capsule().fill(color).frame(width: max(proxy.size.width * used, used > 0 ? 6 : 0))
                if let expected {
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: 2, height: 14)
                        .offset(x: min(max(proxy.size.width * expected - 1, 0), proxy.size.width - 2))
                }
            }
        }
        .frame(height: 14)
        .accessibilityElement()
        .accessibilityLabel("Used \(Int((used * 100).rounded())) percent" +
            (expected.map { ", \(Int(($0 * 100).rounded())) percent of the period has passed" } ?? ""))
    }
}

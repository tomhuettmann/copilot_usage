import Charts
import CopilotUsageCore
import SwiftUI

struct HistoryView: View {
    static let windowID = "history"

    let model: UsageModel
    @State private var period = Period.current
    @State private var confirmClear = false

    enum Period: String, CaseIterable, Identifiable {
        case current = "Current Month"
        case previous = "Previous Month"
        var id: Self { self }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("Period", selection: $period) {
                ForEach(Period.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if let range {
                Text("Per Day").font(.headline)
                dailyChart(range)
                Text("Cumulative").font(.headline)
                cumulativeChart(range)
            } else {
                ContentUnavailableView("No History Yet", systemImage: "chart.bar")
                    .frame(maxHeight: .infinity)
            }

            HStack {
                Button("Clear History…", role: .destructive) { confirmClear = true }
                    .disabled(model.history.isEmpty)
                Spacer()
                Text("\(model.history.samples.count) samples")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 560, height: 520)
        .confirmationDialog(
            "Delete all \(model.history.samples.count) samples?",
            isPresented: $confirmClear
        ) {
            Button("Delete", role: .destructive) { model.clearHistory() }
        } message: {
            Text("This cannot be undone.")
        }
    }

    /// Start and reset date of the selected month.
    private var range: (start: Date, reset: Date)? {
        guard let reset = model.usage?.resetDate ?? model.history.samples.last?.resetDate,
              let start = utc.date(byAdding: .month, value: -1, to: reset)
        else { return nil }
        guard period == .previous else { return (start, reset) }
        guard let previousStart = utc.date(byAdding: .month, value: -1, to: start) else { return nil }
        return (previousStart, start)
    }

    private func dailyChart(_ range: (start: Date, reset: Date)) -> some View {
        let days = model.history.daily(from: range.start, to: min(range.reset, .now))
        let start = Calendar.current.startOfDay(for: range.start)
        return Chart(days, id: \.day) {
            BarMark(x: .value("Day", $0.day, unit: .day), y: .value("Requests", $0.used))
        }
        .chartXScale(domain: start...range.reset)
    }

    private func cumulativeChart(_ range: (start: Date, reset: Date)) -> some View {
        let samples = model.history.samples.filter { $0.resetDate == range.reset }
        let entitlement = samples.last?.entitlement ?? model.usage?.entitlement
        let forecast = period == .current ? model.forecast : nil

        return Chart {
            ForEach(samples, id: \.date) {
                LineMark(x: .value("Date", $0.date), y: .value("Used", $0.used), series: .value("Series", "Used"))
            }
            if let forecast, let last = samples.last {
                LineMark(x: .value("Date", last.date), y: .value("Used", last.used), series: .value("Series", "Forecast"))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(.secondary)
                LineMark(x: .value("Date", range.reset), y: .value("Used", forecast.projectedUsed), series: .value("Series", "Forecast"))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(.secondary)
            }
            if let entitlement {
                RuleMark(y: .value("Quota", entitlement))
                    .foregroundStyle(.red)
                    .annotation(position: .top, alignment: .leading) {
                        Text("Quota \(Formatting.count(entitlement))").font(.caption).foregroundStyle(.red)
                    }
            }
        }
        .chartXScale(domain: range.start...range.reset)
    }

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }
}

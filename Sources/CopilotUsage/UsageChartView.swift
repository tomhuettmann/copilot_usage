import Charts
import CopilotUsageCore
import SwiftUI

struct UsageChartView: View {
    let model: UsageModel
    @State private var mode = Mode.cumulative
    @State private var monthOffset = 0

    enum Mode: String, CaseIterable, Identifiable {
        case cumulative = "Cumulative"
        case daily = "Per Day"
        var id: Self { self }
    }

    private struct Period {
        let start: Date
        let end: Date
    }

    var body: some View {
        VStack(spacing: 8) {
            Picker("Chart", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if let period, hasData(in: period) {
                chart(for: period)
                    .frame(height: 100)
            } else {
                Text("No data for this month")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
                    .frame(height: 100)
            }

            if let period {
                navigator(for: period)
            }
        }
    }

    private func navigator(for period: Period) -> some View {
        HStack {
            if canGoBack(from: period) {
                Button { monthOffset += 1 } label: { Image(systemName: "chevron.left") }
                    .buttonStyle(IconButtonStyle())
                    .accessibilityLabel("Previous month")
            } else {
                Color.clear.frame(width: 26, height: 26)
            }
            Spacer()
            Text(monthLabel(period.start))
                .font(.appBody)
                .foregroundStyle(.secondary)
            Spacer()
            if monthOffset > 0 {
                Button { monthOffset -= 1 } label: { Image(systemName: "chevron.right") }
                    .buttonStyle(IconButtonStyle())
                    .accessibilityLabel("Next month")
            } else {
                Color.clear.frame(width: 26, height: 26)
            }
        }
    }

    @ViewBuilder
    private func chart(for period: Period) -> some View {
        switch mode {
        case .cumulative: cumulativeChart(period)
        case .daily: dailyChart(period)
        }
    }

    private func dailyChart(_ period: Period) -> some View {
        let days = model.history.daily(from: period.start, to: min(period.end, .now))
        let start = Calendar.current.startOfDay(for: period.start)
        return Chart(days, id: \.day) {
            BarMark(x: .value("Day", $0.day, unit: .day), y: .value("Requests", $0.used))
        }
        .chartXScale(domain: start...period.end)
        .chartXAxis { dayAxis }
        .font(.appMeta)
    }

    private func cumulativeChart(_ period: Period) -> some View {
        let samples = model.history.samples.filter { $0.resetDate == period.end }
        let entitlement = samples.last?.entitlement ?? model.usage?.entitlement
        let top = max(entitlement ?? 0, samples.last?.used ?? 0, 1)
        let forecast = monthOffset == 0 ? model.forecast : nil

        return Chart {
            ForEach(samples, id: \.date) {
                LineMark(x: .value("Date", $0.date), y: .value("Used", $0.used), series: .value("Series", "Used"))
            }
            if let forecast, let last = samples.last {
                let end = forecastEnd(forecast, entitlement: entitlement, periodEnd: period.end)
                LineMark(x: .value("Date", last.date), y: .value("Used", last.used), series: .value("Series", "Forecast"))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(.secondary)
                LineMark(x: .value("Date", end.date), y: .value("Used", end.used), series: .value("Series", "Forecast"))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(.secondary)
            }
            if let entitlement {
                RuleMark(y: .value("Quota", entitlement))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(.secondary)
            }
        }
        .chartXScale(domain: period.start...period.end)
        .chartYScale(domain: 0...top)
        .chartXAxis { dayAxis }
        .chartYAxis {
            AxisMarks(values: [0, entitlement ?? top]) {
                AxisGridLine()
                AxisValueLabel(format: IntegerFormatStyle<Int>.number.notation(.compactName))
            }
        }
        .font(.appMeta)
    }

    /// The projection ends on the quota line when the quota runs out, otherwise at the reset.
    private func forecastEnd(_ forecast: Forecast, entitlement: Int?, periodEnd: Date) -> (date: Date, used: Int) {
        if let runOut = forecast.runOutDate, let entitlement {
            return (runOut, entitlement)
        }
        return (periodEnd, forecast.projectedUsed)
    }

    private var dayAxis: some AxisContent {
        AxisMarks(values: .stride(by: .day, count: 7)) {
            AxisGridLine()
            AxisValueLabel(format: .dateTime.day())
        }
    }

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    /// The billing month shown, `monthOffset` months before the current one.
    private var period: Period? {
        guard let reset = model.usage?.resetDate ?? model.history.samples.last?.resetDate,
              let end = utc.date(byAdding: .month, value: -monthOffset, to: reset),
              let start = utc.date(byAdding: .month, value: -1, to: end)
        else { return nil }
        return Period(start: start, end: end)
    }

    private func hasData(in period: Period) -> Bool {
        model.history.samples.contains { $0.resetDate == period.end }
    }

    private func canGoBack(from period: Period) -> Bool {
        guard let first = model.history.samples.first else { return false }
        return first.date < period.start
    }

    private func monthLabel(_ date: Date) -> String {
        var style = Date.FormatStyle().month(.wide).year()
        style.timeZone = TimeZone(identifier: "UTC")!
        return date.formatted(style)
    }
}

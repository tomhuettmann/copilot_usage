import CopilotUsageCore
import SwiftUI

struct SettingsView: View {
    @Bindable var model: UsageModel
    let onBack: () -> Void
    @State private var editingToken = false
    @State private var confirmClear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onBack) {
                Label("Back", systemImage: "chevron.left")
            }
            .buttonStyle(MenuRowStyle())
            .keyboardShortcut(.cancelAction)

            section("Menu bar") {
                VStack(spacing: 0) {
                    ForEach(MenuBarMode.allCases) { mode in
                        menuBarRow(mode)
                    }
                    warningRow
                        .padding(.top, 8)
                }
            }

            section("Token") {
                if editingToken {
                    TokenView(model: model, showsTitle: false) { editingToken = false }
                } else {
                    Text("Stored in your login keychain.")
                        .font(.appBody)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button("Change Token…") { editingToken = true }
                        Button("Remove Token", role: .destructive) {
                            model.removeToken()
                            onBack()
                        }
                    }
                }
            }

            section("History") {
                if confirmClear {
                    Text("Delete \(model.history.samples.count) samples? This cannot be undone.")
                        .font(.appBody)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Button("Cancel") { confirmClear = false }
                        Button("Delete", role: .destructive) {
                            confirmClear = false
                            model.clearHistory()
                        }
                    }
                } else {
                    Text("\(Formatting.count(model.history.samples.count)) recorded samples, kept for 100 days.")
                        .font(.appBody)
                        .foregroundStyle(.secondary)
                    Button("Clear History…", role: .destructive) { confirmClear = true }
                        .disabled(model.history.isEmpty)
                }
            }

            Text("CopilotUsage \(appVersion)")
                .font(.appBody)
                .foregroundStyle(.secondary)
        }
        .onDisappear {
            editingToken = false
            confirmClear = false
        }
    }

    private func menuBarRow(_ mode: MenuBarMode) -> some View {
        let isSelected = model.menuBarMode == mode
        return Button { model.menuBarMode = mode } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                Text(mode.label).font(.appBody)
                Spacer()
                if let usage = model.usage {
                    Text(Formatting.title(for: usage, mode: mode))
                        .font(.appBody.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(MenuRowStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var warningRow: some View {
        let isOn = model.showsForecastWarning
        return Button { model.showsForecastWarning.toggle() } label: {
            HStack {
                Image(systemName: isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isOn ? Color.accentColor : .secondary)
                Text("Show warning when over budget").font(.appBody)
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(MenuRowStyle())
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            Text(title).font(.appHeading)
            content()
        }
        .padding(.horizontal, 6)
    }
}

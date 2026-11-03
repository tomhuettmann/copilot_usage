import CopilotUsageCore
import SwiftUI

struct SettingsView: View {
    let model: UsageModel
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

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            Text(title).font(.appHeading)
            content()
        }
        .padding(.horizontal, 6)
    }
}

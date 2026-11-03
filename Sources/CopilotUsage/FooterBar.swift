import AppKit
import CopilotUsageCore
import SwiftUI

struct FooterBar: View {
    let model: UsageModel
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            if model.hasToken {
                Button {
                    Task { await model.refresh() }
                } label: {
                    if model.isRefreshing {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(IconButtonStyle())
                .keyboardShortcut("r")
                .help("Refresh Now (⌘R)")
                .accessibilityLabel("Refresh")

                Button(action: onSettings) { Image(systemName: "gearshape") }
                    .buttonStyle(IconButtonStyle())
                    .help("Settings")
                    .accessibilityLabel("Settings")
            }

            Button { NSApp.terminate(nil) } label: { Image(systemName: "power") }
                .buttonStyle(IconButtonStyle())
                .keyboardShortcut("q")
                .help("Quit CopilotUsage (⌘Q)")
                .accessibilityLabel("Quit")

            Spacer()

            if let lastUpdated = model.lastUpdated {
                Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                    .font(.appBody)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

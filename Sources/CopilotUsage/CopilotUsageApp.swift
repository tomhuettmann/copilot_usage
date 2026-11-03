import AppKit
import SwiftUI

@main
struct CopilotUsageApp: App {
    @State private var model = UsageModel()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(model: model)
        } label: {
            if model.showsWarning {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("\u{2009}" + model.title)
                }
            } else {
                Text(model.title)
            }
        }
        .menuBarExtraStyle(.window)
    }
}

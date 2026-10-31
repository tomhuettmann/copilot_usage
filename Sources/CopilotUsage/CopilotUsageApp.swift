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
            Text(model.title)
        }

        Window("CopilotUsage", id: TokenView.windowID) {
            TokenView(model: model)
        }
        .windowResizability(.contentSize)
    }
}

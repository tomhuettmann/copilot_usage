import CopilotUsageCore
import SwiftUI

struct MenuRowStyle: ButtonStyle {
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.2 : hovering ? 0.1 : 0))
            )
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
    }
}

struct IconButtonStyle: ButtonStyle {
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 26, height: 26)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.2 : hovering ? 0.1 : 0))
            )
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
    }
}

extension UsageStatus {
    var color: Color {
        switch self {
        case .onTrack: .green
        case .tight: .orange
        case .behind, .exhausted: .red
        }
    }
}

/// The type scale of the menu. Sizes live here so that they can be tuned in one place.
extension Font {
    /// The status line.
    static var appTitle: Font { .system(size: 15, weight: .semibold) }
    /// Section headings.
    static var appHeading: Font { .system(size: 13, weight: .semibold) }
    /// The numbers in the tiles.
    static var appValue: Font { .system(size: 19, weight: .semibold) }
    /// Regular text.
    static var appBody: Font { .system(size: 13) }
    /// Labels and hints.
    static var appMeta: Font { .system(size: 11) }
}

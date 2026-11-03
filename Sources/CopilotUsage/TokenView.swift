import CopilotUsageCore
import SwiftUI

struct TokenView: View {
    let model: UsageModel
    var showsTitle = true
    let onClose: () -> Void
    @State private var token = ""
    @State private var isSaving = false
    @State private var error: UsageError?
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsTitle {
                Text("GitHub Token")
                    .font(.appHeading)
            }
            Text("A personal access token (classic). It is stored in your login keychain.")
                .font(.appBody)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            SecureField("ghp_…", text: $token)
                .focused($focused)
                .onSubmit(save)

            if let error {
                Text(error.message)
                    .font(.appBody)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                if isSaving { ProgressView().controlSize(.small) }
                Spacer()
                if model.hasToken {
                    Button("Cancel", role: .cancel, action: close)
                        .keyboardShortcut(.cancelAction)
                }
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(token.isEmpty || isSaving)
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(150))
            focused = true
        }
        .onDisappear(perform: reset)
    }

    private func reset() {
        token = ""
        error = nil
    }

    private func close() {
        reset()
        onClose()
    }

    private func save() {
        guard !token.isEmpty, !isSaving else { return }
        isSaving = true
        error = nil
        Task {
            defer { isSaving = false }
            do throws(UsageError) {
                try await model.setToken(token)
                close()
            } catch {
                self.error = error
            }
        }
    }
}

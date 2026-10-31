import CopilotUsageCore
import SwiftUI

struct TokenView: View {
    static let windowID = "token"

    let model: UsageModel
    @State private var token = ""
    @State private var isSaving = false
    @State private var error: UsageError?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GitHub Token")
                .font(.headline)
            Text("A personal access token (classic). It is stored in your login keychain.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            SecureField("ghp_…", text: $token)
                .onSubmit(save)

            if let error {
                Text(error.message)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            HStack {
                if isSaving { ProgressView().controlSize(.small) }
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(token.isEmpty || isSaving)
            }
        }
        .padding(20)
        .frame(width: 300)
        .onDisappear {
            token = ""
            error = nil
        }
    }

    private func save() {
        guard !token.isEmpty, !isSaving else { return }
        isSaving = true
        error = nil
        Task {
            defer { isSaving = false }
            do throws(UsageError) {
                try await model.setToken(token)
                token = ""
                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}

import SwiftUI

/// Ports `DeviceTokenEditWindow`: a small modal for typing/editing a single device token.
struct DeviceTokenEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var tokenText: String
    private let onSave: (String) -> Void

    init(initialToken: String = "", onSave: @escaping (String) -> Void) {
        _tokenText = State(initialValue: initialToken)
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Device Token")
                .font(.headline)

            TextEditor(text: $tokenText)
                .font(.system(.body, design: .monospaced))
                .frame(height: 100)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    let trimmed = tokenText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    onSave(trimmed)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 420, height: 200)
    }
}

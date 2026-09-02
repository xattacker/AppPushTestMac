import SwiftUI

/// Ports the `tokenListView` behavior shared by `AndroidFCMWindow` and `IOS_APNsWindow`:
/// a list of device tokens with "Add" button, click-to-edit, and right-click-to-delete
/// (with a confirmation prompt, matching the original's Yes/No message box).
struct DeviceTokenListView: View {
    @Binding var tokens: [String]

    @State private var showAddSheet = false
    @State private var editingToken: EditingToken?
    @State private var pendingDeleteIndex: Int?

    private struct EditingToken: Identifiable {
        let id: Int
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Device Token")
                Spacer()
                Button("Add") { showAddSheet = true }
            }

            List {
                ForEach(Array(tokens.enumerated()), id: \.offset) { index, token in
                    Text(token)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .contentShape(Rectangle())
                        .onTapGesture { editingToken = EditingToken(id: index) }
                        .contextMenu {
                            Button("Edit") { editingToken = EditingToken(id: index) }
                            Button("Delete", role: .destructive) { pendingDeleteIndex = index }
                        }
                }
            }
            .frame(height: 114)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
        }
        .sheet(isPresented: $showAddSheet) {
            DeviceTokenEditView { token in tokens.append(token) }
        }
        .sheet(item: $editingToken) { editing in
            DeviceTokenEditView(initialToken: tokens[editing.id]) { newToken in
                tokens[editing.id] = newToken
            }
        }
        .alert(
            "Delete this token?",
            isPresented: Binding(
                get: { pendingDeleteIndex != nil },
                set: { isPresented in if !isPresented { pendingDeleteIndex = nil } }
            )
        ) {
            Button("Yes", role: .destructive) {
                if let index = pendingDeleteIndex { tokens.remove(at: index) }
                pendingDeleteIndex = nil
            }
            Button("No", role: .cancel) { pendingDeleteIndex = nil }
        }
    }
}

import SwiftUI

/// Ports `AndroidFCMWindow`.
struct AndroidFCMView: View {
    private let recordFilename = "fcm_record.json"

    @State private var projectId = ""
    @State private var accessToken = ""
    @State private var message = ""
    @State private var tokens: [String] = []

    @State private var isSending = false
    @State private var alertMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledContent("Project ID") { TextField("my-firebase-project", text: $projectId) }
            LabeledContent("Access Token") {
                VStack(alignment: .leading, spacing: 2) {
                    TextField("", text: $accessToken)
                    Text("Run `gcloud auth print-access-token` to obtain")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            LabeledContent("Message") { TextField("", text: $message) }

            DeviceTokenListView(tokens: $tokens)

            HStack {
                if isSending {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(height: 16)
                }
                Spacer()
                Button("Send") { send() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 460, height: 440)
        .disabled(isSending)
        .onAppear(perform: load)
        .alert(
            "Notification",
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { isPresented in if !isPresented { alertMessage = nil } }
            ),
            presenting: alertMessage
        ) { _ in
            Button("OK") { alertMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    private func load() {
        guard let record = RecordStore.load(AndroidFCMRecord.self, filename: recordFilename) else { return }
        projectId = record.projectId
        accessToken = record.accessToken
        message = record.message
        tokens = record.tokens
    }

    private func saveRecord() {
        let record = AndroidFCMRecord(projectId: projectId, accessToken: accessToken, message: message, tokens: tokens)
        RecordStore.save(record, filename: recordFilename)
    }

    private func send() {
        guard !projectId.isEmpty, !accessToken.isEmpty, !message.isEmpty, !tokens.isEmpty else {
            alertMessage = "Project ID, Access Token, Message and DeviceToken could not be empty !!"
            return
        }

        saveRecord()
        isSending = true

        Task {
            do {
                let response = try await FCMSender.send(projectId: projectId, accessToken: accessToken, message: message, tokens: tokens)
                isSending = false
                alertMessage = response.isEmpty ? "Sent" : response
            } catch {
                isSending = false
                alertMessage = "error happen: \(error.localizedDescription)"
            }
        }
    }
}

import SwiftUI

/// Ports `AndroidFCMWindow`.
struct AndroidFCMView: View {
    private let recordFilename = "fcm_record.json"

    @State private var appId = ""
    @State private var senderId = ""
    @State private var message = ""
    @State private var tokens: [String] = []

    @State private var isSending = false
    @State private var alertMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledContent("AppId") { TextField("", text: $appId) }
            LabeledContent("SenderId") { TextField("", text: $senderId) }
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
        .frame(width: 460, height: 420)
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
        appId = record.appId
        senderId = record.senderId
        message = record.message
        tokens = record.tokens
    }

    private func saveRecord() {
        let record = AndroidFCMRecord(appId: appId, senderId: senderId, message: message, tokens: tokens)
        RecordStore.save(record, filename: recordFilename)
    }

    private func send() {
        guard !senderId.isEmpty, !appId.isEmpty, !message.isEmpty, !tokens.isEmpty else {
            alertMessage = "SenderId, AppId, Message and DeviceToken could not be empty !!"
            return
        }

        saveRecord()
        isSending = true

        Task {
            do {
                let response = try await FCMSender.send(appId: appId, senderId: senderId, message: message, tokens: tokens)
                isSending = false
                alertMessage = response.isEmpty ? "Sent" : response
            } catch {
                isSending = false
                alertMessage = "error happen: \(error.localizedDescription)"
            }
        }
    }
}

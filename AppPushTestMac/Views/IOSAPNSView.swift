import SwiftUI

/// Ports `IOS_APNsWindow`: certificate (.p12) or auth key (.p8) push, sandbox/production toggle.
struct IOSAPNsView: View {
    private enum AuthTab: String, CaseIterable, Hashable {
        case certificate = "Certificate (P12)"
        case authKey = "Auth Key (P8)"
    }

    private enum ServerMode: Hashable {
        case production
        case sandbox
    }

    private let recordFilename = "apns_record.json"

    @State private var selectedTab: AuthTab = .certificate
    @State private var serverMode: ServerMode = .sandbox

    @State private var certFilePath = ""
    @State private var certPwd = ""

    @State private var keyFilePath = ""
    @State private var keyID = ""
    @State private var teamID = ""
    @State private var bundleID = ""

    @State private var message = ""
    @State private var tokens: [String] = []

    @State private var isSending = false
    @State private var alertMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $selectedTab) {
                ForEach(AuthTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Group {
                if selectedTab == .certificate {
                    certificateForm
                } else {
                    authKeyForm
                }
            }
            .frame(height: 110)

            HStack(spacing: 16) {
                Text("Server Mode")
                Picker("", selection: $serverMode) {
                    Text("Sandbox").tag(ServerMode.sandbox)
                    Text("Production").tag(ServerMode.production)
                }
                .pickerStyle(.radioGroup)
                .horizontalRadioGroupLayout()
                .labelsHidden()
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
        .frame(width: 560, height: 560)
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

    private var certificateForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            LabeledContent("Cert File") {
                HStack {
                    TextField("", text: .constant(certFilePath)).disabled(true)
                    Button("Select") {
                        if let path = FilePicker.selectFile(extensions: ["p12"]) { certFilePath = path }
                    }
                }
            }
            LabeledContent("Cert Password") { SecureField("", text: $certPwd) }
        }
    }

    private var authKeyForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            LabeledContent("Key File") {
                HStack {
                    TextField("", text: .constant(keyFilePath)).disabled(true)
                    Button("Select") {
                        if let path = FilePicker.selectFile(extensions: ["p8"]) { keyFilePath = path }
                    }
                }
            }
            LabeledContent("Key ID") { TextField("", text: $keyID) }
            LabeledContent("Team ID") { TextField("", text: $teamID) }
            LabeledContent("Bundle ID") { TextField("", text: $bundleID) }
        }
    }

    private func load() {
        guard let record = RecordStore.load(IOSAPNsRecord.self, filename: recordFilename) else { return }
        
        certFilePath = record.certificateInfo.certFilePath
        certPwd = record.certificateInfo.certPwd
        keyFilePath = record.authInfo.keyFilePath
        keyID = record.authInfo.keyID
        teamID = record.authInfo.teamID
        bundleID = record.authInfo.bundleID
        message = record.message
        tokens = record.tokens
        serverMode = record.serverMode ? .production : .sandbox
    }

    private func saveRecord() {
        let record = IOSAPNsRecord(
            certificateInfo: APNsCertificateInfo(certFilePath: certFilePath, certPwd: certPwd),
            authInfo: APNsAuthInfo(keyFilePath: keyFilePath, keyID: keyID, teamID: teamID, bundleID: bundleID),
            serverMode: serverMode == .production,
            message: message,
            tokens: tokens
        )
        RecordStore.save(record, filename: recordFilename)
    }

    private func send() {
        switch selectedTab {
        case .certificate:
            guard !certFilePath.isEmpty, !certPwd.isEmpty, !message.isEmpty, !tokens.isEmpty else {
                alertMessage = "Cert file, Cert password, Message and DeviceToken could not be empty !!"
                return
            }
        case .authKey:
            guard !keyFilePath.isEmpty, !keyID.isEmpty, !teamID.isEmpty, !bundleID.isEmpty, !message.isEmpty, !tokens.isEmpty else {
                alertMessage = "Auth Key file, KeyID, TeamID, BundleID, Message and DeviceToken could not be empty !!"
                return
            }
        }

        saveRecord()
        isSending = true

        Task {
            do {
                let results: [String]
                switch selectedTab {
                case .certificate:
                    results = try await APNsCertificateSender.send(
                        certInfo: APNsCertificateInfo(certFilePath: certFilePath, certPwd: certPwd),
                        message: message,
                        tokens: tokens,
                        production: serverMode == .production
                    )
                case .authKey:
                    results = try await APNsTokenSender.send(
                        authInfo: APNsAuthInfo(keyFilePath: keyFilePath, keyID: keyID, teamID: teamID, bundleID: bundleID),
                        message: message,
                        tokens: tokens,
                        production: serverMode == .production
                    )
                }
                isSending = false
                alertMessage = results.joined(separator: "\n")
            } catch {
                isSending = false
                alertMessage = "error happen: \(error.localizedDescription)"
            }
        }
    }
}

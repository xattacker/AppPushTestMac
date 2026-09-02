import Foundation
import Security

enum APNsCertificateError: LocalizedError {
    case importFailed(OSStatus)
    var errorDescription: String? {
        switch self {
        case .importFailed(let status):
            return "Failed to import .p12 certificate (OSStatus \(status)). Check the file and password."
        }
    }
}

/// Sends a push via APNs' HTTP/2 provider API using certificate-based (.p12) authentication.
///
/// The original C# project delegated this to the PushSharp library, which spoke the legacy
/// binary APNs protocol over a persistent socket. Apple's current HTTP/2 provider API accepts
/// the very same certificate for mutual-TLS client authentication on the same
/// `api(.development).push.apple.com` endpoint used for token-based auth, so this uses the
/// system Security framework to import the .p12 into a `SecIdentity` and hands it to
/// `URLSession` via `ClientCertificateSessionDelegate` instead of pulling in a third-party
/// APNs library.
///
/// Note: like the P8 sender, and unlike the original (which only ever pushed to
/// `deviceTokens[0]`), this sends to every token in the list.
enum APNsCertificateSender {
    static func send(certInfo: APNsCertificateInfo, message: String, tokens: [String], production: Bool) async throws -> [String] {
        let (identity, certificates) = try loadIdentity(certInfo: certInfo)
        let delegate = ClientCertificateSessionDelegate(identity: identity, certificates: certificates)
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)

        let host = APNsPushPayload.host(production: production)
        let body = try APNsPushPayload.alertBody(message: message)

        var results: [String] = []
        for token in tokens {
            let url = URL(string: "https://\(host)/3/device/\(token)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(UUID().uuidString, forHTTPHeaderField: "apns-id")
            request.setValue("0", forHTTPHeaderField: "apns-expiration")
            request.setValue("10", forHTTPHeaderField: "apns-priority")
            request.httpBody = body

            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    results.append("\(token): invalid response")
                    continue
                }
                if http.statusCode == 200 {
                    let apnsID = http.value(forHTTPHeaderField: "apns-id") ?? ""
                    results.append("\(token): success (apns-id: \(apnsID))")
                } else {
                    results.append("\(token): failed - \(APNsPushPayload.failureReason(from: data))")
                }
            } catch {
                results.append("\(token): failed - \(error.localizedDescription)")
            }
        }
        return results
    }

    private static func loadIdentity(certInfo: APNsCertificateInfo) throws -> (SecIdentity, [SecCertificate]) {
        let certURL = URL(fileURLWithPath: certInfo.certFilePath)
        let p12Data = try Data(contentsOf: certURL)

        let options: [String: Any] = [kSecImportExportPassphrase as String: certInfo.certPwd]
        var rawItems: CFArray?
        let status = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &rawItems)

        guard status == errSecSuccess,
              let items = rawItems as? [[String: Any]],
              let firstItem = items.first,
              let identity = firstItem[kSecImportItemIdentity as String] else {
            throw APNsCertificateError.importFailed(status)
        }

        let secIdentity = identity as! SecIdentity

        var certificate: SecCertificate?
        SecIdentityCopyCertificate(secIdentity, &certificate)
        let certificates = certificate.map { [$0] } ?? []

        return (secIdentity, certificates)
    }
}

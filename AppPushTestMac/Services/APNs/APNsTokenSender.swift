import Foundation

/// Sends a push via APNs' HTTP/2 provider API using token-based (.p8) authentication.
/// Ports `ApnsTBASender.Push`.
///
/// Difference from the original: the C# version only ever sent to `deviceTokens[0]`, silently
/// ignoring any additional tokens added in the list. Since the UI lets you add several device
/// tokens, this sends to every token in the list and reports one result line per token.
enum APNsTokenSender {
    static func send(authInfo: APNsAuthInfo, message: String, tokens: [String], production: Bool) async throws -> [String] {
        let keyURL = URL(fileURLWithPath: authInfo.keyFilePath)
        let jwt = try APNsJWTSigner.makeToken(keyFileURL: keyURL, keyID: authInfo.keyID, teamID: authInfo.teamID)
        let host = APNsPushPayload.host(production: production)
        let body = try APNsPushPayload.alertBody(message: message)

        var results: [String] = []
        for token in tokens {
            let url = URL(string: "https://\(host)/3/device/\(token)")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("bearer \(jwt)", forHTTPHeaderField: "authorization")
            request.setValue(UUID().uuidString, forHTTPHeaderField: "apns-id")
            request.setValue("0", forHTTPHeaderField: "apns-expiration")
            request.setValue("10", forHTTPHeaderField: "apns-priority")
            request.setValue(authInfo.bundleID, forHTTPHeaderField: "apns-topic")
            request.httpBody = body

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
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
}

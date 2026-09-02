import Foundation

/// Thrown when the FCM legacy HTTP endpoint returns a non-2xx response or a malformed reply.
struct FCMSendError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// FCM v1 HTTP API sender.
///
/// Endpoint: `POST https://fcm.googleapis.com/v1/projects/{projectId}/messages:send`
/// Auth: OAuth2 bearer token — obtain one with `gcloud auth print-access-token` or via a
/// service-account key. The v1 API sends one message per request, so tokens are sent sequentially.
enum FCMSender {
    static func send(projectId: String, accessToken: String, message: String, tokens: [String]) async throws -> String {
        let urlString = "https://fcm.googleapis.com/v1/projects/\(projectId)/messages:send"
        guard let url = URL(string: urlString) else {
            throw FCMSendError(message: "Invalid project ID")
        }

        var results: [String] = []
        for token in tokens {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "message": [
                    "token": token,
                    "notification": [
                        "title": "push notification",
                        "body": message
                    ],
                    "data": [
                        "title": "push notification",
                        "body": message,
                        "sound": "default"
                    ]
                ]
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw FCMSendError(message: "invalid response")
            }

            let text = String(data: data, encoding: .utf8) ?? ""
            guard (200...299).contains(http.statusCode) else {
                throw FCMSendError(message: "HTTP \(http.statusCode): \(text)")
            }
            results.append(text)
        }
        return results.joined(separator: "\n")
    }
}

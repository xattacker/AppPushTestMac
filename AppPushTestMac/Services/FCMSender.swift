import Foundation

/// Thrown when the FCM legacy HTTP endpoint returns a non-2xx response or a malformed reply.
struct FCMSendError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Ports `FCM.Sender.FCMSender` (legacy FCM HTTP API, `https://fcm.googleapis.com/fcm/send`).
///
/// Note: Google deprecated this legacy endpoint in June 2024 in favor of the FCM v1 HTTP API
/// (which needs an OAuth2 service-account token instead of a plain server key). It is kept here
/// unchanged so the ported tool behaves exactly like the original C# app; switch to `POST
/// https://fcm.googleapis.com/v1/projects/{project}/messages:send` with an OAuth bearer token if
/// the legacy key stops working for your project.
enum FCMSender {
    static func send(appId: String, senderId: String, message: String, tokens: [String]) async throws -> String {
        var request = URLRequest(url: URL(string: "https://fcm.googleapis.com/fcm/send")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Matches the original window's field usage: AppId is sent as the legacy server "key",
        // SenderId is sent as the "Sender: id=" header.
        request.setValue("key=\(appId)", forHTTPHeaderField: "Authorization")
        request.setValue("id=\(senderId)", forHTTPHeaderField: "Sender")

        let body: [String: Any] = [
            "registration_ids": tokens,
            "collapse_key": NSNull(),
            "data": [
                "title": "push notification",
                "body": message,
                "sound": "default",
                "category": NSNull()
            ],
            "notification": [
                "title": "push notification",
                "body": message,
                "sound": "default"
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
        return text
    }
}

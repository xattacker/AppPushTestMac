import Foundation

/// Shared helpers used by both the P8 (token) and P12 (certificate) APNs senders.
enum APNsPushPayload {
    /// Builds the `{"aps": {...}}` alert payload, matching `PushMessage`/`PushAps` from the
    /// original C# project (badge fixed at 1, sound fixed at "default").
    static func alertBody(message: String) throws -> Data {
        let payload: [String: Any] = [
            "aps": [
                "alert": message,
                "badge": 1,
                "sound": "default"
            ]
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    static func host(production: Bool) -> String {
        production ? "api.push.apple.com" : "api.development.push.apple.com"
    }

    /// Reads the `reason` field APNs returns in its JSON error body, falling back to the raw body.
    static func failureReason(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let reason = json["reason"] as? String {
            return reason
        }
        return String(data: data, encoding: .utf8) ?? "unknown error"
    }
}

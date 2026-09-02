import Foundation

/// Persisted state for the Android FCM window (FCM v1 API).
struct AndroidFCMRecord: Codable, Equatable, Sendable {
    var projectId: String = ""
    var accessToken: String = ""
    var message: String = ""
    var tokens: [String] = []
}

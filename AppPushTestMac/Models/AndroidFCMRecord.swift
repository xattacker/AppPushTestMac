import Foundation

/// Persisted state for the Android FCM window.
/// Mirrors `AppPush.Data.AndroidFCMRecord` from the original WPF project.
struct AndroidFCMRecord: Codable, Equatable, Sendable {
    var appId: String = ""
    var senderId: String = ""
    var message: String = ""
    var tokens: [String] = []
}

import Foundation

/// Certificate (.p12) based APNs credentials.
/// Mirrors `AppPush.Data.APNSCertificateInfo`.
struct APNSCertificateInfo: Codable, Equatable, Sendable {
    var certFilePath: String = ""
    var certPwd: String = ""
}

/// Auth key (.p8) based APNs credentials.
/// Mirrors `AppPush.Data.APNSAuthInfo`.
struct APNSAuthInfo: Codable, Equatable, Sendable {
    var keyFilePath: String = ""
    var keyID: String = ""
    var teamID: String = ""
    var bundleID: String = ""
}

/// Persisted state for the iOS APNS window.
/// Mirrors `AppPush.Data.IOS_APNSRecord`.
struct IOSAPNSRecord: Codable, Equatable, Sendable {
    var certificateInfo: APNSCertificateInfo = .init()
    var authInfo: APNSAuthInfo = .init()
    /// true = production server, false = sandbox server
    var serverMode: Bool = false
    var message: String = ""
    var tokens: [String] = []
}

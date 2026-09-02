import Foundation

/// Certificate (.p12) based APNs credentials.
/// Mirrors `AppPush.Data.APNsCertificateInfo`.
struct APNsCertificateInfo: Codable, Equatable, Sendable {
    var certFilePath: String = ""
    var certPwd: String = ""
}

/// Auth key (.p8) based APNs credentials.
/// Mirrors `AppPush.Data.APNsAuthInfo`.
struct APNsAuthInfo: Codable, Equatable, Sendable {
    var keyFilePath: String = ""
    var keyID: String = ""
    var teamID: String = ""
    var bundleID: String = ""
}

/// Persisted state for the iOS APNs window.
/// Mirrors `AppPush.Data.IOS_APNsRecord`.
struct IOSAPNsRecord: Codable, Equatable, Sendable {
    var certificateInfo: APNsCertificateInfo = .init()
    var authInfo: APNsAuthInfo = .init()
    /// true = production server, false = sandbox server
    var serverMode: Bool = false
    var message: String = ""
    var tokens: [String] = []
}

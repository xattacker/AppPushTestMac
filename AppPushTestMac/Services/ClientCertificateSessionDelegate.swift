import Foundation

/// Supplies a client identity (certificate + private key) whenever the server challenges for
/// mutual TLS. Used for APNs' certificate-based (.p12) authentication, where the client
/// certificate itself proves identity instead of a JWT bearer token.
final class ClientCertificateSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    private let identity: SecIdentity
    private let certificates: [SecCertificate]

    init(identity: SecIdentity, certificates: [SecCertificate]) {
        self.identity = identity
        self.certificates = certificates
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let credential = URLCredential(identity: identity, certificates: certificates, persistence: .forSession)
        completionHandler(.useCredential, credential)
    }
}

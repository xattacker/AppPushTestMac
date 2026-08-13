import Foundation
import CryptoKit

enum APNsJWTError: LocalizedError {
    case keyLoadFailed(String)
    var errorDescription: String? {
        switch self {
        case .keyLoadFailed(let reason): return "Failed to load APNs auth key: \(reason)"
        }
    }
}

/// Builds the ES256 provider authentication token APNs expects for token-based (.p8) auth.
/// Ports the JWT construction from `ApnsTBASender.Push` (which used `CngKey` + `Jose.JWT` on
/// Windows) using CryptoKit's native P-256 signing, which produces the raw r||s signature JWS
/// expects without any extra ASN.1 handling.
enum APNsJWTSigner {
    static func makeToken(keyFileURL: URL, keyID: String, teamID: String) throws -> String {
        let pem: String
        do {
            pem = try String(contentsOf: keyFileURL, encoding: .utf8)
        } catch {
            throw APNsJWTError.keyLoadFailed(error.localizedDescription)
        }

        let privateKey: P256.Signing.PrivateKey
        do {
            privateKey = try P256.Signing.PrivateKey(pemRepresentation: pem)
        } catch {
            throw APNsJWTError.keyLoadFailed("not a valid ES256 (.p8) private key")
        }

        let header: [String: Any] = ["alg": "ES256", "kid": keyID]
        let payload: [String: Any] = [
            "iss": teamID,
            "iat": Int(Date().timeIntervalSince1970)
        ]

        let headerB64 = try base64URLEncode(jsonObject: header)
        let payloadB64 = try base64URLEncode(jsonObject: payload)
        let signingInput = "\(headerB64).\(payloadB64)"

        let signature = try privateKey.signature(for: Data(signingInput.utf8))

        return "\(signingInput).\(base64URLEncode(signature.rawRepresentation))"
    }

    private static func base64URLEncode(jsonObject: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.sortedKeys])
        return base64URLEncode(data)
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

//
//  GCPJWTGenerator.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation
import SwiftJWT

struct GoogleServiceAccountClaims: Claims {
    let iss: String
    let scope: String
    let aud: String
    let exp: Date
    let iat: Date
}

class GCPJWTGenerator {
    private var credentials: ServiceAccountCredentials? {
        return CredentialManager.shared.credentials
    }

    func generateJWT() throws -> String {
        guard let creds = credentials else {
            throw NSError(domain: "GCPJWTGenerator", code: -1, userInfo: [NSLocalizedDescriptionKey: "Credentials not loaded"])
        }

        let iat = Date()
        let exp = iat.addingTimeInterval(3600)

        let claims = GoogleServiceAccountClaims(
            iss: creds.client_email,
            scope: "https://www.googleapis.com/auth/cloud-platform",
            aud: "https://oauth2.googleapis.com/token",
            exp: exp,
            iat: iat
        )

        var jwt = JWT(claims: claims)
        let formattedPrivateKey = creds.private_key.replacingOccurrences(of: "\\n", with: "\n")

        guard let privateKeyData = formattedPrivateKey.data(using: .utf8) else {
            throw NSError(domain: "GCPJWTGenerator", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid private key format"])
        }

        let jwtSigner = JWTSigner.rs256(privateKey: privateKeyData)
        return try jwt.sign(using: jwtSigner)
    }
}

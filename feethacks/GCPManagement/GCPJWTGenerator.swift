//
//  GCPJWTGenerator.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation
import SwiftJWT

struct GoogleServiceAccountClaims: Claims {
    let iss: String         //service acct email
    let scope: String       //scopes
    let aud: String         //audience
    let exp: Date           //expiration
    let iat: Date           //day issued
}

class GCPJWTGenerator {
    private var credentials: ServiceAccountCredentials? {
        return CredentialManager.shared.credentials
    }
    
    private let scope = "https://www.googleapis.com/auth/devstorage.read_write"
    
    func generateJWT() throws -> String {
        guard let creds = credentials else {
            throw NSError(domain: "GCPJWTGenerator", code: -1, userInfo: [NSLocalizedDescriptionKey: "Credentials not loaded"])
        }
        
        let iat = Date()
        let exp = iat.addingTimeInterval(3600) // 1 hour validity
        
        let claims = GoogleServiceAccountClaims(
            iss: creds.client_email,
            scope: scope,
            aud: "https://oauth2.googleapis.com/token",
            exp: exp,
            iat: iat
        )
        
        var jwt = JWT(claims: claims)
        
        // Convert the escaped newline characters into actual newlines.
        let formattedPrivateKey = creds.private_key.replacingOccurrences(of: "\\n", with: "\n")
        let privateKeyData = Data(formattedPrivateKey.utf8)
        let jwtSigner = JWTSigner.rs256(privateKey: privateKeyData)
        
        return try jwt.sign(using: jwtSigner)
    }
}

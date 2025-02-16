//
//  GCPAuthManager.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation
import SwiftJWT

class GCPAuthManager {
    func fetchAccessToken(completion: @escaping (String?) -> Void) {
        guard let creds = CredentialManager.shared.credentials else {
            print("Credentials not loaded")
            completion(nil)
            return
        }

        let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let jwt: String
        do {
            jwt = try GCPJWTGenerator().generateJWT()
        } catch {
            print("Error generating JWT: \(error.localizedDescription)")
            completion(nil)
            return
        }

        let requestBody = [
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": jwt
        ].map { "\($0.key)=\($0.value)" }
         .joined(separator: "&")

        request.httpBody = requestBody.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching OAuth token: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received from token endpoint")
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let accessToken = json["access_token"] as? String {

                    self.fetchIdToken(using: accessToken, completion: completion)
                } else {

                    completion(nil)
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

    private func fetchIdToken(using accessToken: String, completion: @escaping (String?) -> Void) {
        guard let creds = CredentialManager.shared.credentials else {
            print("Credentials not loaded")
            completion(nil)
            return
        }

        let targetAudience = "https://us-central1-able-plating-451020-e1.cloudfunctions.net/process_ply"
        let url = URL(string: "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/\(creds.client_email):generateIdToken")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "audience": targetAudience,
            "includeEmail": true
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            print("Failed to encode request body")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching ID token: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data else {
                print("No data received from IAM API")
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let idToken = json["token"] as? String {
                    print("ID Token retrieved successfully.")
                    completion(idToken)
                } else {
                    completion(nil)
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
}

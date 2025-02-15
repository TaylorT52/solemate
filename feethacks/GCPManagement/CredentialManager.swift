//
//  CredentialManager.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation

struct ServiceAccountCredentials: Codable {
    let type: String
    let project_id: String
    let private_key_id: String
    let private_key: String
    let client_email: String
    let client_id: String
}

class CredentialManager {
    static let shared = CredentialManager()
    
    private(set) var credentials: ServiceAccountCredentials?
    
    private init() {
        loadCredentials()
    }
    
    private func loadCredentials() {
        guard let url = Bundle.main.url(forResource: "service-account", withExtension: "json") else {
            print("Service account file not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            credentials = try decoder.decode(ServiceAccountCredentials.self, from: data)
        } catch {
            print("Error loading service account credentials: \(error.localizedDescription)")
        }
    }
}

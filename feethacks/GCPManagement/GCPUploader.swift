//
//  GCPUploader.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation
import SwiftUI

class GCPUploader {
    let cloudFunctionURL = "https://us-central1-able-plating-451020-e1.cloudfunctions.net/process_ply"

    func uploadFile(data: Data, fileName: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: cloudFunctionURL) else {
            print("Invalid Cloud Function URL")
            completion(false, nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let base64EncodedData = data.base64EncodedString()
        let requestBody: [String: Any] = [
            "fileName": fileName,
            "fileData": base64EncodedData
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            print("Failed to encode request body: \(error.localizedDescription)")
            completion(false, nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Upload error: \(error.localizedDescription)")
                completion(false, nil)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("Response Code: \(httpResponse.statusCode)")
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                print("Upload failed with response: \(String(describing: response))")
                completion(false, nil)
                return
            }

            if let filePath = String(data: data, encoding: .utf8) {
                print("File uploaded successfully! Received processed file path: \(filePath)")
                completion(true, filePath)
            } else {
                print("Failed to decode response data")
                completion(false, nil)
            }
        }.resume()
    }
}

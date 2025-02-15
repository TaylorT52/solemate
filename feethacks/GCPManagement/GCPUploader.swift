//
//  GCPUploader.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation
import SwiftUI

class GCPUploader {
    let bucketName = "scan_uploads"
    
    //uploads file
    func uploadFile(data: Data, fileName: String, completion: @escaping (Bool) -> Void) {
        //fetch access token from auth manager
        let authManager = GCPAuthManager()
        authManager.fetchAccessToken { token in
            guard let token = token else {
                print("Failed to fetch access token.")
                completion(false)
                return
            }
            
            //construct upload url
            let urlString = "https://www.googleapis.com/upload/storage/v1/b/\(self.bucketName)/o?uploadType=media&name=\(fileName)"
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                completion(false)
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Upload error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) {
                    print("File uploaded successfully!")
                    completion(true)
                } else {
                    print("Upload failed with response: \(String(describing: response))")
                    completion(false)
                }
            }
            
            task.resume()
        }
    }
}

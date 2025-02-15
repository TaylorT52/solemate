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
    
    var accessToken: String {
        return "ACCESS TOKEN HERE"
    }
    
    func uploadFile(data: Data, fileName: String, completion: @escaping (Bool) -> Void) {
        let urlString = "https://console.cloud.google.com/storage/browser/scan_uploads"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Set the OAuth access token in the Authorization header.
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
       
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
               print("Upload error: \(error.localizedDescription)")
               completion(false)
               return
           }
           
           if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
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

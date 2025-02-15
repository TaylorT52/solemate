//
//  GCPAuthManager.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation

class GCPAuthManager {
    //fetches access token
    func fetchAccessToken(completion: @escaping (String?) -> Void) {
        let jwtGenerator = GCPJWTGenerator()
        
        do {
            //jwt assertion using credentials
            let jwtAssertion = try jwtGenerator.generateJWT()
            
            //construct token url
            guard let url = URL(string: "https://oauth2.googleapis.com/token") else {
                print("Invalid token URL")
                completion(nil)
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            //post body
            let params = [
                "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
                "assertion": jwtAssertion
            ]
            let bodyString = params.map { "\($0)=\($1)" }.joined(separator: "&")
            request.httpBody = bodyString.data(using: .utf8)
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            //jwt for access token
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error fetching token: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let data = data else {
                    print("No data received from token endpoint")
                    completion(nil)
                    return
                }
                
                do {
                    //parse the json response
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let accessToken = json["access_token"] as? String {
                        print("Access Token: \(accessToken)")
                        completion(accessToken)
                    } else {
                        print("Could not parse access token from response: \(String(data: data, encoding: .utf8) ?? "Invalid Data")")
                        completion(nil)
                    }
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                    completion(nil)
                }
            }.resume()
        } catch {
            print("Error generating JWT: \(error.localizedDescription)")
            completion(nil)
        }
    }
}

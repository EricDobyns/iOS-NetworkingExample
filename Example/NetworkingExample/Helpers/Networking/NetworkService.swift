//
//  NetworkService.swift
//
//  Created by Eric Dobyns & Luis Garcia.
//  Copyright © 2017 Eric Dobyns & Luis Garcia. All rights reserved.
//

import Foundation

// MARK: - NetworkService
open class NetworkService: NSObject {

    // Request Resource From Server
    open func request<A>(resource: NetworkResource<A>, completion: @escaping (NetworkResult<A>) -> ()) {
        
        // Return Error - Invalid Resource
        guard let request = URLRequest(resource: resource) else {
            completion(NetworkResult.error(NetworkError.invalidResource))
            return            
        }
        
        // Create session with configuration
        let session = URLSession.shared

        // Print Request Info
        #if DEBUG
            if let url = request.url?.absoluteString, let headers = request.allHTTPHeaderFields {
                self.printRequest(url: url, headers: headers, body: request.httpBody)
            }
        #endif
        
        session.dataTask(with: request) {data, response, error in
            
            // Print Response Info
            #if DEBUG
                self.printResponse(data: data, response: response, error: error)
            #endif

            // Return Error - Passed from server
            if let error = error {
                completion(.error(NetworkError.serverError(message: error.localizedDescription)))
                return
            }
            
            // Return Error - No Server Response
            guard let data = data else {
                completion(.error(NetworkError.serverError(message: "There was no data returned from the server")))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 401:
                    completion(.error(NetworkError.serverError(message: "Unauthorized")))
                    return
                case 404:
                    completion(.error(NetworkError.serverError(message: "Not Found")))
                    return
                case 429:
                    completion(.error(NetworkError.serverError(message: "Too Many Requests")))
                    return
                case 498:
                    completion(.error(NetworkError.serverError(message: "Expired Token")))
                    return
                default:
                    break
                }
            }
            
            do {
                // Return Success
                if let result = try resource.parse(data) {
                    completion(.success(result))
                    return
                } else {
                    // Return Error - Could not parse data
                    completion(.error(NetworkError.serverError(message: "Could not parse the data returned from the server.")))
                    return
                }
            } catch {
                // Return Error - Could not retrieve data
                completion(.error(NetworkError.serverError(message: "Could not deserialize or decode the data")))
                return
            }
        }.resume()
    }

    // Cancel All Requests
    open func cancelAllRequests() {
        URLSession.shared.invalidateAndCancel()
    }

    
    // MARK: - Debug Methods
    private func printRequest(url: String, headers: [String: String], body: Data?) {
        print("\nRequest: ")
        print("==============================================================")
        print("Url: \(url)")
        print("--------------------------------------------------------------")
        print("Headers:")
        print(headers)
        print("--------------------------------------------------------------")
        print("Body:")
        if let body = body, let requestBody = String(data: body, encoding: .utf8) {
            print(requestBody)
        } else {
            print("No HTTP Body")
        }
        print("==============================================================\n")
    }
    
    private func printResponse(data: Data?, response: URLResponse?, error: Error?) {
        print("Response: ")
        print("==============================================================")
        if let urlString = response?.url?.absoluteString {
            print("Url: \(String(describing: urlString))")
        }
        if let httpResponse = response as? HTTPURLResponse {
            print("Status: \(httpResponse.statusCode)")
            print("--------------------------------------------------------------")
            print("Headers:")
            print(httpResponse.allHeaderFields)
        }
        print("--------------------------------------------------------------")
        print("Body:")
        if let data = data, let body = String(data: data, encoding: .utf8) {
            print (body)
        }
        print("--------------------------------------------------------------")
        print("Error:")
        print(error ?? "Nil")
        print("==============================================================\n\n")
    }
}

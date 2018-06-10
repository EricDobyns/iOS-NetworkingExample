//
//  NetworkParameterEncoding.swift
//
//  Created by Eric Dobyns & Luis Garcia.
//  Copyright © 2017 Eric Dobyns & Luis Garcia. All rights reserved.
//

import Foundation

// MARK: - Parameter Encoding Type
public enum NetworkParameterEncoding {
    case json
    case url
    case path
    
    public func contentType() -> String {
        switch self {
        case .json:
            return "application/json"
        case .url, .path:
            return "application/x-www-form-urlencoded"
        }
    }
}


// MARK: - Dictionary Extension

extension Dictionary { //  Adds multiple parameter encoding types to Dictionary
    
    var urlEncodedString: String? { // Convert dictionary to query variables (URL Encoded String)
        
        var encodedArray = [String]()
        
        for (key, value) in self {
            
            guard let key = key as? NSString else {
                assertionFailure("Parsing error")
                return nil
            }
            
            guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                assertionFailure("Parsing error")
                return nil
            }
            
            guard let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                assertionFailure("Parsing error")
                return nil
            }
            
            encodedArray.append("\(encodedKey)=\(encodedValue)")
        }
        
        return encodedArray.joined(separator: "&")
    }
    
    
    var jsonEncodedData: Data? { // Convert dictionary to json
        return try? JSONSerialization.data(withJSONObject: self, options: [])
    }
}

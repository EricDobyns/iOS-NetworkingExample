//
//  NetworkResource.swift
//
//  Created by Eric Dobyns & Luis Garcia.
//  Copyright © 2017 Eric Dobyns & Luis Garcia. All rights reserved.
//

import Foundation

// MARK: - Network Result Type
public enum NetworkResult<A> {
    case success(A)
    case error(NetworkError)
}



// MARK: - APIResource Model
public struct NetworkResource<A: Decodable> {
    public let url: String
    public let headers: [String: String]?
    public let parameters: Decodable?
    public let httpMethod: NetworkHttpMethod
    public let encoding: NetworkParameterEncoding
    public let parse: (Data) throws -> A?
}



// MARK: - APIResource Init
extension NetworkResource {
    
    // Initialize with api endpoint and return data type
    public init(endpoint: HTTPEndpoint) {
        self.init(endpoint: endpoint.name, parameters: endpoint.parameters, headers: endpoint.headers, httpMethod: endpoint.method, encoding: endpoint.encoding)
    }
    
    // Initialize all fields
    private init(endpoint: String,
                 parameters: Decodable? = nil,
                 headers: [String: String]? = nil,
                 httpMethod: NetworkHttpMethod = .get,
                 encoding: NetworkParameterEncoding = .json) {
        
        self.url = endpoint
        self.headers = headers
        self.parameters = parameters
        self.httpMethod = httpMethod
        self.encoding = encoding
        self.parse = { data in
            let encodedData = try JSONDecoder().decode(A.self, from: data)
            return encodedData
        }
    }
}


// URLRequest + NetworkResource Extension
extension URLRequest {
    public init?<A>(resource: NetworkResource<A>) {
        
        var endpointUrl = resource.url
        
        var parameters: [String: Any] = [:]
        if let params: [String: Any] = resource.parameters as? [String : Any] {
            parameters = params
        }
        
        var body: Data? = nil
        
        switch resource.encoding {
        case .json:
            if resource.parameters != nil {
                body = parameters.jsonEncodedData
            }
        case .url:
            if let parameters = parameters.urlEncodedString {
                endpointUrl += "?\(parameters)"
            }
        case .path:
            if let parameters = resource.parameters as? String {
                endpointUrl += "/\(parameters)"
            }
        }
        
        guard let url = URL(string: endpointUrl) else { return nil }
        
        self.init(url: url)
        
        // Set Body
        httpBody = body
        
        // Set HTTP Method
        httpMethod = resource.httpMethod.rawValue
        
        // Add General Headers
        addValue(resource.encoding.contentType(), forHTTPHeaderField: "Content-Type")
        addValue(resource.encoding.contentType(), forHTTPHeaderField: "Accept")
        
        // Add Endpoint Headers
        if let headers = resource.headers {
            for (key, value) in headers {
                addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add API Key Header
        if let path = Bundle.main.path(forResource: "Config", ofType: "json") {
            do {
                // If able to parse the Config.json file then continue
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any]
                
                if let apiKey = json?["apiKey"] as? String {
                    addValue(apiKey, forHTTPHeaderField: "apiKey")
                } else {
                    // Else prevent developer from running the app
                    print("DEVELOPER WARNING: Please include a valid Config.json file.")
                    fatalError()
                }
            } catch {
                // Else prevent developer from running the app
                print("DEVELOPER WARNING: Please include a valid Config.json file.")
                fatalError()
            }
        }
    }
}


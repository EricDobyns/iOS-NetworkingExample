//
//  HTTPEndpoint
//
//  Created by Eric Dobyns & Luis Garcia.
//  Copyright © 2017 Eric Dobyns & Luis Garcia. All rights reserved.
//

import Foundation

// MARK: - HTTP Endpoint Protocol
public protocol HTTPEndpoint {
    var name: String { get }
    var parameters: Decodable? { get }
    var headers: [String: String]? { get }
    var method: NetworkHttpMethod { get }
    var encoding: NetworkParameterEncoding { get }
}



// MARK: - HTTP Method Enum
public enum NetworkHttpMethod: String {
    case get =      "GET"
    case post =     "POST"
    case put =      "PUT"
    case patch =    "PATCH"
    case delete =   "DELETE"
    case head =     "HEAD"
}



// Fetch HTTP Endpoint
public func fetch<A: Decodable>(endpoint: HTTPEndpoint, completion: @escaping (NetworkResult<A>) -> ()) {
    NetworkService().request(resource: NetworkResource<A>(endpoint: endpoint)) { result in
        switch result {
        case .success(let response):
            completion(NetworkResult<A>.success(response))
        case .error(let error):
            completion(NetworkResult<A>.error(error))
        }
    }
}



// MARK: - Parameter Encoding Type
public enum NetworkParameterEncoding {
    case json
    case url
    case path
    case graphql
    
    public func contentType() -> String {
        switch self {
        case .json:
            return "application/json"
        case .url, .path:
            return "application/x-www-form-urlencoded"
        case .graphql:
            return "ERROR: TODO - Add this!"
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




// MARK: - Network Error Types
public enum NetworkError: Error {
    case genericError
    case invalidResource
    case serverError(message: String)
}

extension NetworkError: LocalizedError {
    
    var localizedDescription: String {
        switch self {
        case .genericError:
            return "An error has occurred. Please try again."
        case .invalidResource:
            return "Invalid parameters sent to the server."
        case .serverError(let message):
            return message
        }
    }
}



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
        case .graphql:
            print("Error: TODO - Add this!")
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




//
// JSONResource
//

public enum JSON {
    case string(String)
    case number(Float)
    case object([String:JSON])
    case array([JSON])
    case bool(Bool)
    case null
}

extension JSON: Equatable {
    
    public static func == (lhs: JSON, rhs: JSON) -> Bool {
        switch (lhs, rhs) {
        case (.string(let s1), .string(let s2)):
            return s1 == s2
        case (.number(let n1), .number(let n2)):
            return n1 == n2
        case (.object(let o1), .object(let o2)):
            return o1 == o2
        case (.array(let a1), .array(let a2)):
            return a1 == a2
        case (.bool(let b1), .bool(let b2)):
            return b1 == b2
        case (.null, .null):
            return true
        default:
            return false
        }
    }
}

extension JSON: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .string(let str):
            return str.debugDescription
        case .number(let num):
            return num.debugDescription
        case .bool(let bool):
            return bool.description
        case .null:
            return "null"
        default:
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            return try! String(data: encoder.encode(self), encoding: .utf8)!
        }
    }
}

extension JSON {
    
    /// Create a JSON value from anything. Argument has to be a valid JSON structure:
    /// A `Float`, `Int`, `String`, `Bool`, an `Array` of those types or a `Dictionary`
    /// of those types.
    public init(_ value: Any) throws {
        switch value {
        case let num as Float:
            self = .number(num)
        case let num as Int:
            self = .number(Float(num))
        case let str as String:
            self = .string(str)
        case let bool as Bool:
            self = .bool(bool)
        case let array as [Any]:
            self = .array(try array.map(JSON.init))
        case let dict as [String:Any]:
            self = .object(try dict.mapValues(JSON.init))
        default:
            throw JSONError.decodingError
        }
    }
}

extension JSON {
    
    /// Create a JSON value from a `Codable`. This will give you access to the “raw”
    /// encoded JSON value the `Codable` is serialized into. And hopefully, you could
    /// encode the resulting JSON value and decode the original `Codable` back.
    public init<T: Codable>(codable: T) throws {
        let encoded = try JSONEncoder().encode(codable)
        self = try JSONDecoder().decode(JSON.self, from: encoded)
    }
}

extension JSON: ExpressibleByBooleanLiteral {
    
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension JSON: ExpressibleByNilLiteral {
    
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension JSON: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: JSON...) {
        self = .array(elements)
    }
}

extension JSON: ExpressibleByDictionaryLiteral {
    
    public init(dictionaryLiteral elements: (String, JSON)...) {
        var object: [String:JSON] = [:]
        for (k, v) in elements {
            object[k] = v
        }
        self = .object(object)
    }
}

extension JSON: ExpressibleByFloatLiteral {
    
    public init(floatLiteral value: Float) {
        self = .number(value)
    }
}

extension JSON: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: Int) {
        self = .number(Float(value))
    }
}

extension JSON: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension JSON: Decodable {
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        
        if let object = try? container.decode([String: JSON].self) {
            self = .object(object)
        } else if let array = try? container.decode([JSON].self) {
            self = .array(array)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Float.self) {
            self = .number(number)
        } else if container.decodeNil() {
            self = .null
        } else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Invalid JSON value.")
            )
        }
    }
}

extension JSON: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        
        switch self {
        case let .array(array):
            try container.encode(array)
        case let .object(object):
            try container.encode(object)
        case let .string(string):
            try container.encode(string)
        case let .number(number):
            try container.encode(number)
        case let .bool(bool):
            try container.encode(bool)
        case .null:
            try container.encodeNil()
        }
    }
}

public enum JSONError: Swift.Error {
    case decodingError
}




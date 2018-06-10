import Foundation

/// A JSON value representation. This is a bit more useful than the naïve `[String:Any]` type
/// for JSON values, since it makes sure only valid JSON values are present & supports `Equatable`
/// and `Codable`, so that you can compare values for equality and code and decode them into data
/// or strings.
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

//
//  GeneralRoutes.swift
//  

public enum GeneralRoutes: HTTPEndpoint {
    case status
    case compatibility
    
    public var name: String {
        switch self {
        case .status: return API_ENVIRONMENT + "/status"
        case .compatibility: return API_ENVIRONMENT + "/compatibility"
        }
    }
    
    public var method: NetworkHttpMethod {
        switch self {
        case .status, .compatibility: return .get
        }
    }
    
    public var headers: [String: String]? {
        switch self {
        case .status, .compatibility: return nil
        }
    }
    
    public var parameters: Decodable? {
        switch self {
        case .status, .compatibility: return nil
        }
    }
    
    public var encoding: NetworkParameterEncoding {
        switch self {
        case .status, .compatibility: return .json
        }
    }
}







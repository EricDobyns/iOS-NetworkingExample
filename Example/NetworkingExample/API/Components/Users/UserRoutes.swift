//
//  UserRoutes.swift
//

public enum UserRoutes: HTTPEndpoint {
    case getUser
    
    public var name: String {
        switch self {
        case .getUser: return "https://randomuser.me/api/"
        }
    }
    
    public var method: NetworkHttpMethod {
        switch self {
        case .getUser: return .get
        }
    }
    
    public var headers: [String: String]? {
        switch self {
        case .getUser: return nil
        }
    }
    
    public var parameters: Decodable? {
        switch self {
        case .getUser: return nil
        }
    }
    
    public var encoding: NetworkParameterEncoding {
        switch self {
        case .getUser: return .json
        }
    }
}







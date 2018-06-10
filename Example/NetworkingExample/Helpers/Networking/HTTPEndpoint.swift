//
//  HTTPEndpoint
//
//  Created by Eric Dobyns & Luis Garcia.
//  Copyright © 2017 Eric Dobyns & Luis Garcia. All rights reserved.
//

public protocol HTTPEndpoint {
    var name: String { get }
    var method: NetworkHttpMethod { get }
    var headers: [String: String]? { get }
    var parameters: Decodable? { get }
    var encoding: NetworkParameterEncoding { get }
}

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

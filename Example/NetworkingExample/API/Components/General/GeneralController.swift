//
//  GeneralController.swift
//  

extension API.General {
    public static func getStatus(completion: @escaping (NetworkResult<JSON>) -> ()) {
        fetch(endpoint: GeneralRoutes.status) { (result: NetworkResult<JSON>) in
            completion(result)
        }
    }
    
    public static func getCompatibility(completion: @escaping (NetworkResult<JSON>) -> ()) {
        fetch(endpoint: GeneralRoutes.compatibility) { (result: NetworkResult<JSON>) in
            completion(result)
        }
    }
}

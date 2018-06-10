//
//  UserController.swift
//

extension API.Users {
    public static func getUser(completion: @escaping (NetworkResult<RandomUser>) -> ()) {
        fetch(endpoint: UserRoutes.getUser) { (result: NetworkResult<RandomUser>) in
            completion(result)
        }
    }
}

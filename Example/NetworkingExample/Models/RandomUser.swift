// To parse the JSON, add this file to your project and do:
//
//   let randomUser = try RandomUser(json)

import Foundation

public struct RandomUser: Codable {
    let results: [Result]
}

struct Result: Codable {
    let name: Name
    let picture: Picture
}

struct Name: Codable {
    let title, first, last: String
}

struct Picture: Codable {
    let large, medium, thumbnail: String
}

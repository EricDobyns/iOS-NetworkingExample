//
//  NetworkError.swift
//
//  Created by Eric Dobyns & Luis Garcia.
//  Copyright © 2017 Eric Dobyns & Luis Garcia. All rights reserved.
//

import Foundation


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

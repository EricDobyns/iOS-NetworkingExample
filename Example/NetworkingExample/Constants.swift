//
//  Constants.swift
//  


/*
 *    API CONSTANTS
 */

// MARK: - API Settings
let API_ENVIRONMENT   = APIEnvironment.local.rawValue
let API_VERSION       = APIVersion.one.rawValue



// MARK: - API Environment
public enum APIEnvironment: String {
    case local       = "http://MacBook-Pro.local:3000/api"
    case staging     = "insert staging url"
    case production  = "insert production url"
}



// MARK: - API Version
public enum APIVersion: String {
    case one = "/v1"
}




import Foundation

enum APIConfig {
    #if DEBUG
    static let baseURL = "http://localhost:9000/api"
    #else
    static let baseURL = "https://api.getdoto.com/api"
    #endif
}

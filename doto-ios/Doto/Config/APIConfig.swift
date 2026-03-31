import Foundation

enum AppEnvironment {
    case local
    case production

    var baseURL: String {
        switch self {
        case .local:      return "http://localhost:9000/api"
        case .production: return "https://doto-api-5e3a07135be3.herokuapp.com/api"
        }
    }
}

enum APIConfig {
    static let environment: AppEnvironment = .production  // ← change this line only
    static var baseURL: String { environment.baseURL }
}

import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case notFound
    case validation(String)
    case conflict(String)
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .unauthorized:          return "Please log in again."
        case .notFound:              return "Not found."
        case .validation(let msg):   return msg
        case .conflict(let msg):     return msg
        case .serverError(let msg):  return "Server error: \(msg)"
        case .decodingError(let e):
            if let ctx = e as? DecodingError {
                switch ctx {
                case .keyNotFound(let key, let context):
                    return "Missing field '\(key.stringValue)' at: \(context.codingPath.map(\.stringValue).joined(separator: "."))"
                case .typeMismatch(_, let context):
                    return "Wrong type at: \(context.codingPath.map(\.stringValue).joined(separator: "."))"
                case .valueNotFound(_, let context):
                    return "Null non-optional at: \(context.codingPath.map(\.stringValue).joined(separator: "."))"
                case .dataCorrupted(let context):
                    return "Corrupted at: \(context.codingPath.map(\.stringValue).joined(separator: ".")) — \(context.debugDescription)"
                @unknown default:
                    break
                }
            }
            return "Decode error: \(e)"
        case .networkError(let e):   return "Network error: \(e.localizedDescription)"
        case .unknown:               return "An unexpected error occurred."
        }
    }
}

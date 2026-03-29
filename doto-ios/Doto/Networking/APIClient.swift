import Foundation

class APIClient {
    static let shared = APIClient()
    private let session = URLSession.shared

    func get<T: Decodable>(_ path: String, params: [String: String] = [:]) async throws -> T {
        try await request(method: "GET", path: path, params: params, body: nil as EmptyBody?)
    }

    func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request(method: "POST", path: path, params: [:], body: body)
    }

    func put<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request(method: "PUT", path: path, params: [:], body: body)
    }

    func patch<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request(method: "PATCH", path: path, params: [:], body: body)
    }

    func patch<T: Decodable>(_ path: String) async throws -> T {
        try await request(method: "PATCH", path: path, params: [:], body: nil as EmptyBody?)
    }

    func delete(_ path: String) async throws {
        let _: EmptyResponse = try await request(method: "DELETE", path: path, params: [:], body: nil as EmptyBody?)
    }

    private func request<B: Encodable, T: Decodable>(
        method: String, path: String, params: [String: String], body: B?
    ) async throws -> T {
        var components = URLComponents(string: APIConfig.baseURL + path)!
        if !params.isEmpty {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw APIError.unknown }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainHelper.loadToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = try JSONEncoder.iso8601.encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.unknown }

        let rawJSON = String(data: data, encoding: .utf8) ?? "<binary>"
        NSLog("[DOTO] [\(method)] \(path) → HTTP \(http.statusCode)")
        NSLog("[DOTO] RAW: %@", rawJSON)

        switch http.statusCode {
        case 200, 201:
            do {
                return try JSONDecoder.iso8601.decode(T.self, from: data)
            } catch {
                NSLog("[DOTO] DECODE ERROR for \(T.self) on \(path): \(error)")
                if let ctx = error as? DecodingError {
                    switch ctx {
                    case .keyNotFound(let key, let context):
                        NSLog("[DOTO]   Missing key '%@' at %@", key.stringValue, context.codingPath.map(\.stringValue).joined(separator: "."))
                    case .typeMismatch(let type, let context):
                        NSLog("[DOTO]   Type mismatch: expected %@ at %@", String(describing: type), context.codingPath.map(\.stringValue).joined(separator: "."))
                    case .valueNotFound(let type, let context):
                        NSLog("[DOTO]   Value not found: %@ at %@", String(describing: type), context.codingPath.map(\.stringValue).joined(separator: "."))
                    case .dataCorrupted(let context):
                        NSLog("[DOTO]   Data corrupted at %@: %@", context.codingPath.map(\.stringValue).joined(separator: "."), context.debugDescription)
                    @unknown default:
                        break
                    }
                }
                throw APIError.decodingError(error)
            }
        case 204:
            if let empty = EmptyResponse() as? T { return empty }
            throw APIError.unknown
        case 400:
            let err = try? JSONDecoder.iso8601.decode(APIErrorResponse.self, from: data)
            throw APIError.validation(err?.message ?? "Validation error")
        case 401, 403:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 409:
            let err = try? JSONDecoder.iso8601.decode(APIErrorResponse.self, from: data)
            throw APIError.conflict(err?.message ?? "Conflict")
        default:
            let err = try? JSONDecoder.iso8601.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(err?.message ?? "Unknown error")
        }
    }
}

struct EmptyBody: Encodable {}
struct EmptyResponse: Decodable {}
struct APIErrorResponse: Decodable { let code: String; let message: String }

extension JSONEncoder {
    static var iso8601: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }
}

extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)

            // Play Framework emits microseconds e.g. "2026-03-29T16:48:13.839073Z".
            // ISO8601DateFormatter only handles up to 3 fractional digits, so truncate.
            var normalized = str
            if let dotIdx = str.firstIndex(of: "."),
               let zIdx = str.lastIndex(of: "Z") {
                let fracStart = str.index(after: dotIdx)
                let fracPart = str[fracStart..<zIdx]
                if fracPart.count > 3 {
                    normalized = String(str[str.startIndex...dotIdx])
                        + String(fracPart.prefix(3))
                        + "Z"
                }
            }

            let fmtFrac = ISO8601DateFormatter()
            fmtFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fmtFrac.date(from: normalized) { return date }

            let fmtPlain = ISO8601DateFormatter()
            fmtPlain.formatOptions = [.withInternetDateTime]
            if let date = fmtPlain.date(from: normalized) { return date }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(str)"
            )
        }
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }
}

import Foundation

enum APIError: Error {
    case unauthorized
    case httpError(Int)
    case networkError(Error)
    case decodingError(Error)
    case invalidResponse
    case invalidURL

    var userMessage: String {
        switch self {
        case .unauthorized:
            return String(localized: "error.unauthorized")
        case .httpError(let code):
            return String(localized: "error.httpError \(code)")
        case .networkError:
            return String(localized: "error.networkError")
        case .decodingError:
            return String(localized: "error.decodingError")
        case .invalidResponse:
            return String(localized: "error.invalidResponse")
        case .invalidURL:
            return String(localized: "error.invalidURL")
        }
    }
}

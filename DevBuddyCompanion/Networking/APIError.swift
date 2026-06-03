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
            return "Token inválido ou expirado"
        case .httpError(let code):
            return "Erro do servidor (\(code))"
        case .networkError:
            return "Sem conexão com o servidor"
        case .decodingError:
            return "Resposta inesperada do servidor"
        case .invalidResponse:
            return "Resposta inválida"
        case .invalidURL:
            return "URL inválida"
        }
    }
}

import Foundation

enum APIError: LocalizedError, Sendable {
    case invalidURL
    case unauthorized
    case forbidden
    case notFound
    case validationError(String)
    case serverError(Int, String?)
    case networkError(String)
    case decodingError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .forbidden:
            return "You don't have permission to perform this action."
        case .notFound:
            return "The requested resource was not found."
        case .validationError(let message):
            return message
        case .serverError(_, let message):
            return message ?? "An unexpected server error occurred."
        case .networkError(let message):
            return message
        case .decodingError(let message):
            return "Failed to process response: \(message)"
        case .unknown(let message):
            return message
        }
    }
}

struct APIErrorResponse: Decodable, Sendable {
    let error: String?
    let message: String?

    var displayMessage: String {
        error ?? message ?? "An unknown error occurred."
    }
}

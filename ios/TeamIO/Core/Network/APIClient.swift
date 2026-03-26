import Foundation

actor APIClient {
    static let shared = APIClient()

    #if DEBUG
    private let baseURL = "http://localhost:8082/api"
    #else
    private let baseURL = "https://api.getteamio.com/api"
    #endif

    private let session: URLSession
    private let decoder = JSONDecoder.api
    private let encoder = JSONEncoder.api
    private var isRefreshing = false

    private var orgSlug: String?
    private var orgId: String?

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Org Context

    func setOrgContext(slug: String?, id: String?) {
        self.orgSlug = slug
        self.orgId = id
    }

    // MARK: - Request Methods

    func request<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        body: (some Encodable & Sendable)? = nil as String?,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let data = try await performRequest(endpoint, body: body, queryItems: queryItems)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    func requestVoid(
        _ endpoint: APIEndpoint,
        body: (some Encodable & Sendable)? = nil as String?,
        queryItems: [URLQueryItem]? = nil
    ) async throws {
        _ = try await performRequest(endpoint, body: body, queryItems: queryItems)
    }

    // MARK: - Core Request Logic

    private func performRequest(
        _ endpoint: APIEndpoint,
        body: (some Encodable & Sendable)?,
        queryItems: [URLQueryItem]?
    ) async throws -> Data {
        let urlRequest = try await buildRequest(endpoint, body: body, queryItems: queryItems)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown("Invalid response")
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            if endpoint.requiresAuth {
                return try await handleUnauthorized(
                    endpoint: endpoint, body: body, queryItems: queryItems
                )
            }
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw APIError.validationError(errorResponse.displayMessage)
            }
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 422:
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                throw APIError.validationError(errorResponse.displayMessage)
            }
            throw APIError.validationError("Validation failed")
        case 500...599:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(httpResponse.statusCode, errorResponse?.displayMessage)
        default:
            let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.unknown(errorResponse?.displayMessage ?? "Request failed with status \(httpResponse.statusCode)")
        }
    }

    private func buildRequest(
        _ endpoint: APIEndpoint,
        body: (some Encodable)?,
        queryItems: [URLQueryItem]?
    ) async throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }

        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let slug = orgSlug {
            request.setValue(slug, forHTTPHeaderField: "X-Org-Slug")
        }
        if let id = orgId {
            request.setValue(id, forHTTPHeaderField: "X-Org-Id")
        }

        if endpoint.requiresAuth, let token = await TokenManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    // MARK: - Token Refresh

    private func handleUnauthorized(
        endpoint: APIEndpoint,
        body: (some Encodable & Sendable)?,
        queryItems: [URLQueryItem]?
    ) async throws -> Data {
        guard !isRefreshing else {
            throw APIError.unauthorized
        }

        isRefreshing = true
        defer { isRefreshing = false }

        guard let refreshToken = await TokenManager.shared.refreshToken else {
            throw APIError.unauthorized
        }

        let refreshEndpoint = APIEndpoint.refreshToken()
        let refreshBody = TokenRefreshRequest(refresh_token: refreshToken)

        let refreshRequest = try await buildRequest(refreshEndpoint, body: refreshBody, queryItems: nil)
        let (data, response) = try await session.data(for: refreshRequest)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            await TokenManager.shared.clearTokens()
            throw APIError.unauthorized
        }

        let tokens = try decoder.decode(TokenRefreshResponse.self, from: data)
        await TokenManager.shared.store(accessToken: tokens.access_token, refreshToken: tokens.refresh_token)

        return try await performRequest(endpoint, body: body, queryItems: queryItems)
    }
}

// MARK: - Token Refresh Models

private struct TokenRefreshRequest: Encodable, Sendable {
    let refresh_token: String
}

private struct TokenRefreshResponse: Decodable, Sendable {
    let access_token: String
    let refresh_token: String
}

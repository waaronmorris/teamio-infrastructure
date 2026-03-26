import Foundation
import Observation

enum AuthState: Equatable, Sendable {
    case loading
    case unauthenticated
    case authenticated
}

@Observable
@MainActor
final class AuthManager {
    var state: AuthState = .loading
    var currentUser: User?
    var currentOrganization: Organization?
    var error: String?

    init() {
        Task {
            await checkExistingSession()
        }
    }

    // MARK: - Session Check

    private func checkExistingSession() async {
        let hasToken = await TokenManager.shared.isAuthenticated
        guard hasToken else {
            state = .unauthenticated
            return
        }

        do {
            let user: User = try await APIClient.shared.request(.me())
            self.currentUser = user
            state = .authenticated
        } catch {
            await TokenManager.shared.clearTokens()
            state = .unauthenticated
        }
    }

    // MARK: - Login

    func login(email: String, password: String) async {
        error = nil
        do {
            let request = LoginRequest(email: email, password: password)
            let response: AuthResponse = try await APIClient.shared.request(.login(), body: request)
            await TokenManager.shared.store(
                accessToken: response.access_token,
                refreshToken: response.refresh_token
            )
            self.currentUser = response.user
            state = .authenticated
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Register

    func register(email: String, password: String, firstName: String, lastName: String) async {
        error = nil
        do {
            let request = RegisterRequest(
                email: email,
                password: password,
                first_name: firstName,
                last_name: lastName
            )
            let response: AuthResponse = try await APIClient.shared.request(.register(), body: request)
            await TokenManager.shared.store(
                accessToken: response.access_token,
                refreshToken: response.refresh_token
            )
            self.currentUser = response.user
            state = .authenticated
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Forgot Password

    func forgotPassword(email: String) async -> Bool {
        error = nil
        do {
            let request = ForgotPasswordRequest(email: email)
            try await APIClient.shared.requestVoid(.forgotPassword(), body: request)
            return true
        } catch let apiError as APIError {
            self.error = apiError.localizedDescription
            return false
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    // MARK: - Logout

    func logout() async {
        do {
            try await APIClient.shared.requestVoid(.logout())
        } catch {
            // Best effort — still clear local state
        }
        await TokenManager.shared.clearTokens()
        currentUser = nil
        currentOrganization = nil
        state = .unauthenticated
    }

    // MARK: - Org Context

    func setOrganization(_ org: Organization) async {
        currentOrganization = org
        await APIClient.shared.setOrgContext(slug: org.slug, id: org.id)
    }
}

// MARK: - Auth Request/Response Models

struct LoginRequest: Encodable, Sendable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable, Sendable {
    let email: String
    let password: String
    let first_name: String
    let last_name: String
}

struct ForgotPasswordRequest: Encodable, Sendable {
    let email: String
}

struct AuthResponse: Decodable, Sendable {
    let access_token: String
    let refresh_token: String
    let token_type: String?
    let expires_in: Int?
    let user: User
}

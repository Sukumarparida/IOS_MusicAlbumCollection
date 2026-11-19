import Foundation

/// Errors related to credential authentication.
enum AuthError: LocalizedError, Equatable {
    case emptyFields
    case invalidUsernameLength(minimum: Int)
    case invalidPasswordLength(minimum: Int)
    case passwordsDoNotMatch
    case invalidCredentials
    case noCredentialsConfigured
    case storageFailure(String)

    var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "Please enter both username and password."
        case .invalidUsernameLength(let min):
            return "Username must be at least \(min) characters."
        case .invalidPasswordLength(let min):
            return "Password must be at least \(min) characters."
        case .passwordsDoNotMatch:
            return "Passwords do not match."
        case .invalidCredentials:
            return "Invalid username or password."
        case .noCredentialsConfigured:
            return "No credentials configured yet. Please set up your login credentials."
        case .storageFailure(let message):
            return "Credential storage error: \(message)"
        }
    }
}

/// Defines operations for authenticating user credentials via secure Keychain.
protocol AuthServiceProtocol: Sendable {
    func hasStoredCredentials() -> Bool
    func getStoredUsername() -> String?
    func saveCredentials(username: String, password: String) throws
    func validateCredentials(username: String, password: String) -> Result<Void, AuthError>
}

/// Keychain-backed implementation of AuthServiceProtocol.
struct AuthService: AuthServiceProtocol {
    private let keychainService: KeychainServiceProtocol

    init(keychainService: KeychainServiceProtocol = KeychainService()) {
        self.keychainService = keychainService
    }

    func hasStoredCredentials() -> Bool {
        keychainService.hasCredentials()
    }

    func getStoredUsername() -> String? {
        keychainService.getCredentials()?.username
    }

    func saveCredentials(username: String, password: String) throws {
        try keychainService.saveCredentials(username: username, password: password)
    }

    func validateCredentials(username: String, password: String) -> Result<Void, AuthError> {
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedUser.isEmpty || password.isEmpty {
            return .failure(.emptyFields)
        }
        if trimmedUser.count < AppConstants.Validation.minimumUsernameLength {
            return .failure(.invalidUsernameLength(minimum: AppConstants.Validation.minimumUsernameLength))
        }
        if password.count < AppConstants.Validation.minimumPasswordLength {
            return .failure(.invalidPasswordLength(minimum: AppConstants.Validation.minimumPasswordLength))
        }

        guard let stored = keychainService.getCredentials() else {
            return .failure(.noCredentialsConfigured)
        }

        if stored.username.lowercased() == trimmedUser.lowercased() && stored.password == password {
            return .success(())
        }

        return .failure(.invalidCredentials)
    }
}

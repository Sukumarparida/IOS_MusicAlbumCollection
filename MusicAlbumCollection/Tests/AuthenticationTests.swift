import Testing
import Foundation

// MARK: - Mock Keychain Service

final class MockKeychainService: KeychainServiceProtocol, @unchecked Sendable {
    var storedCredentials: (username: String, password: String)? = nil

    func saveCredentials(username: String, password: String) throws {
        storedCredentials = (username, password)
    }

    func getCredentials() -> (username: String, password: String)? {
        storedCredentials
    }

    func hasCredentials() -> Bool {
        storedCredentials != nil
    }

    func deleteCredentials() throws {
        storedCredentials = nil
    }
}

// MARK: - Mock Biometric Service

final class MockBiometricService: BiometricServiceProtocol, @unchecked Sendable {
    var mockBiometricType: BiometricType = .faceID
    var mockStatusToReturn: BiometricStatus = .success

    var biometricType: BiometricType {
        mockBiometricType
    }

    func canAuthenticate() -> (isAvailable: Bool, status: BiometricStatus) {
        switch mockStatusToReturn {
        case .notAvailable:
            return (false, .notAvailable)
        case .notEnrolled:
            return (false, .notEnrolled)
        default:
            return (true, .idle)
        }
    }

    func authenticate() async -> BiometricStatus {
        mockStatusToReturn
    }
}

// MARK: - Authentication Tests

@Suite("Authentication Module Tests")
struct AuthenticationTests {

    @Test("Biometric status messages match all requirements")
    func biometricStatusMessages() {
        #expect(BiometricStatus.success.displayMessage == "Authentication successful.")
        #expect(BiometricStatus.notAvailable.displayMessage == "Face ID not available.")
        #expect(BiometricStatus.notEnrolled.displayMessage == "Face ID not enrolled.")
        #expect(BiometricStatus.cancelled.displayMessage == "Authentication cancelled.")
        #expect(BiometricStatus.failed(message: "").displayMessage == "Authentication failed.")
    }

    @Test("Keychain service correctly saves, retrieves and clears credentials")
    func keychainOperations() throws {
        let mockKeychain = MockKeychainService()
        #expect(!mockKeychain.hasCredentials())

        try mockKeychain.saveCredentials(username: "musicadmin", password: "securepassword123")
        #expect(mockKeychain.hasCredentials())

        let retrieved = mockKeychain.getCredentials()
        #expect(retrieved?.username == "musicadmin")
        #expect(retrieved?.password == "securepassword123")

        try mockKeychain.deleteCredentials()
        #expect(!mockKeychain.hasCredentials())
        #expect(mockKeychain.getCredentials() == nil)
    }

    @Test("AuthService validates fields and enforces rules")
    func authServiceValidation() throws {
        let mockKeychain = MockKeychainService()
        let authService = AuthService(keychainService: mockKeychain)

        // Empty fields validation
        let emptyResult = authService.validateCredentials(username: "", password: "")
        guard case .failure(let emptyError) = emptyResult else {
            Issue.record("Expected failure for empty fields")
            return
        }
        #expect(emptyError == .emptyFields)

        // Username length validation
        let shortUserResult = authService.validateCredentials(username: "ab", password: "validPassword1")
        guard case .failure(let shortUserError) = shortUserResult else {
            Issue.record("Expected failure for short username")
            return
        }
        #expect(shortUserError == .invalidUsernameLength(minimum: 3))

        // Password length validation
        let shortPassResult = authService.validateCredentials(username: "validUser", password: "12")
        guard case .failure(let shortPassError) = shortPassResult else {
            Issue.record("Expected failure for short password")
            return
        }
        #expect(shortPassError == .invalidPasswordLength(minimum: 4))

        // No credentials configured
        let noCredsResult = authService.validateCredentials(username: "validUser", password: "password123")
        guard case .failure(let noCredsError) = noCredsResult else {
            Issue.record("Expected failure when no credentials configured")
            return
        }
        #expect(noCredsError == .noCredentialsConfigured)

        // Valid credentials configured and matched
        try authService.saveCredentials(username: "masterUser", password: "secretPassword")
        let matchResult = authService.validateCredentials(username: "masterUser", password: "secretPassword")
        guard case .success = matchResult else {
            Issue.record("Expected match success")
            return
        }

        // Wrong password
        let mismatchResult = authService.validateCredentials(username: "masterUser", password: "wrongPassword")
        guard case .failure(let mismatchError) = mismatchResult else {
            Issue.record("Expected failure for mismatched password")
            return
        }
        #expect(mismatchError == .invalidCredentials)
    }

    @Test("Face ID authentication success transitions to authenticated state")
    @MainActor
    func biometricSuccessFlow() async {
        let mockBiometric = MockBiometricService()
        mockBiometric.mockStatusToReturn = .success

        let mockKeychain = MockKeychainService()
        let authService = AuthService(keychainService: mockKeychain)

        let viewModel = AuthenticationViewModel(
            biometricService: mockBiometric,
            authService: authService
        )

        #expect(!viewModel.isAuthenticated)
        await viewModel.authenticateWithFaceID()

        #expect(viewModel.biometricStatus == .success)
        #expect(viewModel.isAuthenticated)
        #expect(viewModel.authState == .authenticated)
        #expect(viewModel.successMessage == "Authentication successful.")
    }

    @Test("Face ID failure provides clear error and keeps manual login available")
    @MainActor
    func biometricFailureFlow() async {
        let mockBiometric = MockBiometricService()
        mockBiometric.mockStatusToReturn = .failed(message: "Face did not match")

        let mockKeychain = MockKeychainService()
        let authService = AuthService(keychainService: mockKeychain)

        let viewModel = AuthenticationViewModel(
            biometricService: mockBiometric,
            authService: authService
        )

        await viewModel.authenticateWithFaceID()

        #expect(!viewModel.isAuthenticated)
        #expect(viewModel.errorMessage != nil)

        // Manual authentication is accessible
        viewModel.openManualAuthentication()
        #expect(viewModel.activeScreen != .biometric)
    }

    @Test("Face ID cancelled status displays clear cancellation message")
    @MainActor
    func biometricCancelledFlow() async {
        let mockBiometric = MockBiometricService()
        mockBiometric.mockStatusToReturn = .cancelled

        let mockKeychain = MockKeychainService()
        let authService = AuthService(keychainService: mockKeychain)

        let viewModel = AuthenticationViewModel(
            biometricService: mockBiometric,
            authService: authService
        )

        await viewModel.authenticateWithFaceID()

        #expect(!viewModel.isAuthenticated)
        #expect(viewModel.errorMessage == "Authentication cancelled.")
    }

    @Test("Logout resets session and requires re-authentication")
    @MainActor
    func logoutFlow() async {
        let mockBiometric = MockBiometricService()
        mockBiometric.mockStatusToReturn = .success

        let mockKeychain = MockKeychainService()
        let authService = AuthService(keychainService: mockKeychain)

        let viewModel = AuthenticationViewModel(
            biometricService: mockBiometric,
            authService: authService
        )

        await viewModel.authenticateWithFaceID()
        #expect(viewModel.isAuthenticated)

        viewModel.logout()

        #expect(!viewModel.isAuthenticated)
        #expect(viewModel.authState == .unauthenticated)
        #expect(viewModel.activeScreen == .biometric)
        #expect(viewModel.password.isEmpty)
    }
}

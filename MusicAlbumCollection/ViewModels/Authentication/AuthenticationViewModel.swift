import SwiftUI
import Combine

/// View model driving the authentication module with Face ID, Keychain storage, and manual fallback.
@MainActor
final class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var authState: AuthSessionState = .unauthenticated
    @Published var biometricStatus: BiometricStatus = .idle
    @Published var activeScreen: AuthenticationScreen = .biometric

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    @Published var hasExistingCredentials: Bool = false
    @Published var showLogoutConfirmation: Bool = false

    private let biometricService: BiometricServiceProtocol
    private let authService: AuthServiceProtocol
    private var isFirstLaunch: Bool = true

    /// Initializes AuthenticationViewModel with biometric and authentication service dependencies.
    /// - Parameters:
    ///   - biometricService: Service handling LocalAuthentication Face ID operations.
    ///   - authService: Service managing Keychain-backed credentials.
    init(
        biometricService: BiometricServiceProtocol? = nil,
        authService: AuthServiceProtocol? = nil
    ) {
        let auth = authService ?? AuthService()
        self.biometricService = biometricService ?? BiometricService()
        self.authService = auth
        self.hasExistingCredentials = auth.hasStoredCredentials()
        if let storedUsername = auth.getStoredUsername() {
            self.username = storedUsername
        }
    }

    /// Discovers biometric sensor on device (Face ID, Touch ID, or None).
    var biometricType: BiometricType {
        biometricService.biometricType
    }

    /// Primary biometric display name (defaulting to Face ID as requested).
    var biometricDisplayName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Face ID"
        }
    }

    /// Face ID / biometric icon name.
    var biometricIconName: String {
        switch biometricType {
        case .faceID, .none:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        }
    }

    // MARK: - Biometric Authentication

    /// Automatically initiates Face ID on application launch, or explicitly when prompted.
    func handleOnAppear() async {
        guard isFirstLaunch else { return }
        isFirstLaunch = false
        await authenticateWithFaceID()
    }

    /// Triggers Face ID verification via LocalAuthentication framework.
    func authenticateWithFaceID() async {
        guard !isLoading else { return }
        errorMessage = nil
        successMessage = nil
        biometricStatus = .authenticating

        let status = await biometricService.authenticate()
        biometricStatus = status

        switch status {
        case .success:
            successMessage = "Authentication successful."
            errorMessage = nil
            // Brief visual affirmation before transitioning to Dashboard
            try? await Task.sleep(nanoseconds: 350_000_000)
            isAuthenticated = true
            authState = .authenticated

        case .notAvailable:
            errorMessage = "Face ID not available."

        case .notEnrolled:
            errorMessage = "Face ID not enrolled."

        case .cancelled:
            errorMessage = "Authentication cancelled."

        case .failed(let message):
            errorMessage = message.isEmpty ? "Authentication failed." : message

        case .idle, .authenticating:
            break
        }
    }

    // MARK: - Manual Login

    /// Validates inputs and authenticates against securely stored Keychain credentials.
    func login() async {
        errorMessage = nil
        successMessage = nil

        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedUser.isEmpty || password.isEmpty {
            errorMessage = "Please enter both username and password."
            return
        }
        if trimmedUser.count < AppConstants.Validation.minimumUsernameLength {
            errorMessage = "Username must be at least \(AppConstants.Validation.minimumUsernameLength) characters."
            return
        }
        if password.count < AppConstants.Validation.minimumPasswordLength {
            errorMessage = "Password must be at least \(AppConstants.Validation.minimumPasswordLength) characters."
            return
        }

        isLoading = true
        // Realistic asynchronous execution for button loading state
        try? await Task.sleep(nanoseconds: 250_000_000)

        let result = authService.validateCredentials(username: trimmedUser, password: password)
        isLoading = false

        switch result {
        case .success:
            password = ""
            errorMessage = nil
            isAuthenticated = true
            authState = .authenticated
        case .failure(let error):
            errorMessage = error.errorDescription
        }
    }

    // MARK: - First-Time Credential Setup

    /// First-time credential setup when no credentials exist in the Keychain.
    func setupFirstTimeCredentials() async {
        errorMessage = nil
        successMessage = nil

        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedUser.isEmpty || password.isEmpty || confirmPassword.isEmpty {
            errorMessage = "Please enter both username and password."
            return
        }
        if trimmedUser.count < AppConstants.Validation.minimumUsernameLength {
            errorMessage = "Username must be at least \(AppConstants.Validation.minimumUsernameLength) characters."
            return
        }
        if password.count < AppConstants.Validation.minimumPasswordLength {
            errorMessage = "Password must be at least \(AppConstants.Validation.minimumPasswordLength) characters."
            return
        }
        if password != confirmPassword {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true
        do {
            try authService.saveCredentials(username: trimmedUser, password: password)
            hasExistingCredentials = true
            password = ""
            confirmPassword = ""
            isLoading = false
            successMessage = "Credentials saved successfully."
            try? await Task.sleep(nanoseconds: 300_000_000)
            isAuthenticated = true
            authState = .authenticated
        } catch {
            isLoading = false
            errorMessage = "Failed to save credentials to Keychain: \(error.localizedDescription)"
        }
    }

    // MARK: - Navigation Between Auth Screens

    /// Directs user to manual login or first-time setup depending on Keychain status.
    func openManualAuthentication() {
        errorMessage = nil
        successMessage = nil
        hasExistingCredentials = authService.hasStoredCredentials()
        if hasExistingCredentials {
            activeScreen = .manualLogin
        } else {
            activeScreen = .firstTimeSetup
        }
    }

    /// Returns user to biometric landing screen.
    func returnToBiometricScreen() {
        errorMessage = nil
        successMessage = nil
        activeScreen = .biometric
    }

    // MARK: - Logout

    /// Confirms and performs logout, resetting all credentials and locking access.
    func logout() {
        isAuthenticated = false
        authState = .unauthenticated
        activeScreen = .biometric
        biometricStatus = .idle
        password = ""
        confirmPassword = ""
        errorMessage = nil
        successMessage = nil
        showLogoutConfirmation = false
        isFirstLaunch = false
    }
}

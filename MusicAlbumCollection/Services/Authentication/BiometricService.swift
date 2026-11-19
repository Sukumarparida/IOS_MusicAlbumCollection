import Foundation
import LocalAuthentication

/// Wraps Apple's LocalAuthentication framework to perform biometric evaluation and return standardized BiometricStatus states.
struct BiometricService: BiometricServiceProtocol {

    /// Discovers the active biometric hardware type on the current device.
    var biometricType: BiometricType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }

    /// Evaluates whether biometric authentication can currently be performed on this device.
    /// - Returns: A tuple with availability boolean and initial BiometricStatus.
    func canAuthenticate() -> (isAvailable: Bool, status: BiometricStatus) {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if canEvaluate {
            return (true, .idle)
        }

        guard let laError = error else {
            return (false, .notAvailable)
        }

        if laError.code == LAError.biometryNotEnrolled.rawValue {
            return (false, .notEnrolled)
        } else {
            return (false, .notAvailable)
        }
    }

    /// Initiates biometric authentication prompt via LocalAuthentication framework.
    /// - Returns: BiometricStatus representing success, cancellation, or failure.
    func authenticate() async -> BiometricStatus {
        let context = LAContext()
        context.localizedCancelTitle = AppConstants.Auth.biometricCancelTitle

        var checkError: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &checkError) else {
            if let error = checkError {
                if error.code == LAError.biometryNotEnrolled.rawValue {
                    return .notEnrolled
                } else if error.code == LAError.biometryNotAvailable.rawValue {
                    return .notAvailable
                }
            }
            return .notAvailable
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: AppConstants.Auth.biometricReason
            )
            return success ? .success : .failed(message: "Authentication failed.")
        } catch let laError as LAError {
            switch laError.code {
            case .userCancel, .appCancel, .systemCancel:
                return .cancelled
            case .biometryNotAvailable:
                return .notAvailable
            case .biometryNotEnrolled:
                return .notEnrolled
            case .authenticationFailed:
                return .failed(message: "Authentication failed.")
            case .biometryLockout:
                return .failed(message: "Authentication failed.")
            default:
                return .failed(message: "Authentication failed.")
            }
        } catch {
            return .failed(message: "Authentication failed.")
        }
    }
}

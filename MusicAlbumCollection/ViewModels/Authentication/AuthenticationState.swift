import Foundation
import SwiftUI

/// Top-level user session state.
enum AuthSessionState: Equatable, Sendable {
    case unauthenticated
    case authenticating
    case authenticated
}

/// The hardware biometric sensor available on this device.
enum BiometricType: String, Equatable, Sendable {
    case none = "None"
    case touchID = "Touch ID"
    case faceID = "Face ID"
    case opticID = "Optic ID"

    /// SF Symbol icon name corresponding to this biometric hardware type.
    var iconName: String {
        switch self {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.shield"
        }
    }
}

/// Status of the most recent biometric authentication attempt.
enum BiometricStatus: Equatable, Sendable {
    case idle
    case authenticating
    case success
    case notAvailable
    case notEnrolled
    case cancelled
    case failed(message: String)

    /// User-facing descriptive message required by the authentication module.
    var displayMessage: String? {
        switch self {
        case .idle:
            return nil
        case .authenticating:
            return "Verifying identity..."
        case .success:
            return "Authentication successful."
        case .notAvailable:
            return "Face ID not available."
        case .notEnrolled:
            return "Face ID not enrolled."
        case .cancelled:
            return "Authentication cancelled."
        case .failed(let message):
            return message.isEmpty ? "Authentication failed." : message
        }
    }

    /// Color associated with this status in the UI.
    var statusColor: Color {
        switch self {
        case .idle, .authenticating:
            return .accentColor
        case .success:
            return .green
        case .notAvailable, .notEnrolled, .cancelled:
            return .orange
        case .failed:
            return .red
        }
    }

    /// Icon associated with this status in the UI.
    var statusIcon: String {
        switch self {
        case .idle:
            return "faceid"
        case .authenticating:
            return "arrow.triangle.2.circlepath"
        case .success:
            return "checkmark.circle.fill"
        case .notAvailable, .notEnrolled:
            return "exclamationmark.triangle.fill"
        case .cancelled:
            return "xmark.circle"
        case .failed:
            return "xmark.circle.fill"
        }
    }
}

/// Active screen within the authentication flow.
enum AuthenticationScreen: Equatable, Sendable {
    case biometric
    case manualLogin
    case firstTimeSetup
}

import Foundation

/// Defines biometric authentication capabilities and hardware discovery.
protocol BiometricServiceProtocol: Sendable {
    var biometricType: BiometricType { get }
    func canAuthenticate() -> (isAvailable: Bool, status: BiometricStatus)
    func authenticate() async -> BiometricStatus
}

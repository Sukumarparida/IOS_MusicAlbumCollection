import SwiftUI

/// Professional biometric authentication landing screen initiating Face ID on launch.
struct AuthenticationView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @State private var isPulsing = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        brandingHeader
                            .padding(.top, 40)

                        biometricCard

                        statusBanner

                        if shouldShowManualLoginOffer {
                            manualLoginOfferCard
                        }

                        actionControls
                            .padding(.top, 8)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .task {
                await viewModel.handleOnAppear()
            }
            .sheet(isPresented: Binding(
                get: { viewModel.activeScreen != .biometric },
                set: { isPresented in
                    if !isPresented {
                        viewModel.returnToBiometricScreen()
                    }
                }
            )) {
                LoginView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Header

    private var brandingHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 96, height: 96)

                Image(systemName: "music.note.list")
                    .font(.system(size: 46))
                    .foregroundStyle(Color.accentColor)
            }

            Text("Music Album Collection")
                .font(.title2.bold())

            Text("Unlock your music collection with Face ID")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Biometric Card

    private var biometricCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(
                        viewModel.biometricStatus == .authenticating
                            ? Color.accentColor.opacity(0.4)
                            : Color.secondary.opacity(0.15),
                        lineWidth: 3
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(isPulsing ? 1.08 : 1.0)
                    .animation(
                        viewModel.biometricStatus == .authenticating
                            ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                            : .default,
                        value: isPulsing
                    )

                Image(systemName: viewModel.biometricIconName)
                    .font(.system(size: 60))
                    .foregroundStyle(viewModel.biometricStatus.statusColor)
            }
            .onAppear {
                isPulsing = true
            }

            VStack(spacing: 4) {
                Text(viewModel.biometricDisplayName)
                    .font(.headline)

                Text(statusSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .cardStyle()
    }

    private var statusSubtitle: String {
        switch viewModel.biometricStatus {
        case .idle:
            return "Tap below to authenticate"
        case .authenticating:
            return "Verifying identity..."
        case .success:
            return "Access granted"
        case .notAvailable:
            return "Biometrics not available on this device"
        case .notEnrolled:
            return "No Face ID enrolled in iOS Settings"
        case .cancelled:
            return "Authentication was cancelled"
        case .failed:
            return "Biometric recognition could not verify you"
        }
    }

    // MARK: - Status Banner

    @ViewBuilder
    private var statusBanner: some View {
        if let message = viewModel.successMessage {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.green)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.green.opacity(0.12), in: Capsule())
        } else if let message = viewModel.errorMessage {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.red.opacity(0.12), in: Capsule())
        }
    }

    // MARK: - Manual Login Offer

    private var shouldShowManualLoginOffer: Bool {
        switch viewModel.biometricStatus {
        case .notAvailable, .notEnrolled, .failed, .cancelled:
            return true
        case .idle, .authenticating, .success:
            return false
        }
    }

    private var manualLoginOfferCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Color.accentColor)
                Text("Manual Login Available")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Spacer()
            }

            Text("You can sign in securely with your master username and password.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Controls

    private var actionControls: some View {
        VStack(spacing: 14) {
            Button {
                Task {
                    await viewModel.authenticateWithFaceID()
                }
            } label: {
                Label("Authenticate with \(viewModel.biometricDisplayName)", systemImage: viewModel.biometricIconName)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                viewModel.openManualAuthentication()
            } label: {
                Label(
                    viewModel.hasExistingCredentials ? "Log In with Password" : "Set Up Password",
                    systemImage: "lock.shield"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }
}

#Preview {
    AuthenticationView(viewModel: AuthenticationViewModel())
}

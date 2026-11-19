import SwiftUI

/// Manual login and secure first-time credential setup screen.
struct LoginView: View {
    @ObservedObject var viewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isConfirmPasswordVisible: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                        .padding(.top, 20)

                    credentialsForm

                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }

                    if let success = viewModel.successMessage {
                        successBanner(success)
                    }

                    actionButtons
                        .padding(.top, 8)

                    modeSwitchSection
                }
                .padding(24)
            }
            .navigationTitle(viewModel.activeScreen == .firstTimeSetup ? "Setup Credentials" : "Manual Login")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        viewModel.returnToBiometricScreen()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: viewModel.activeScreen == .firstTimeSetup ? "key.fill" : "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text(viewModel.activeScreen == .firstTimeSetup ? "First-Time Security Setup" : "Sign In with Password")
                .font(.title3.bold())

            Text(
                viewModel.activeScreen == .firstTimeSetup
                    ? "Create your administrator credentials. They will be stored securely in the iOS Keychain."
                    : "Enter your master credentials to unlock your album collection."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
    }

    // MARK: - Form

    private var credentialsForm: some View {
        VStack(spacing: 16) {
            // Username field
            VStack(alignment: .leading, spacing: 6) {
                Text("Username")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                TextField("Enter username", text: $viewModel.username)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            // Password field with visibility toggle
            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                HStack {
                    if viewModel.isPasswordVisible {
                        TextField("Enter password", text: $viewModel.password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("Enter password", text: $viewModel.password)
                    }

                    Button {
                        viewModel.isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(viewModel.isPasswordVisible ? "Hide password" : "Show password")
                }
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            }

            // Confirm Password (in first-time setup mode)
            if viewModel.activeScreen == .firstTimeSetup {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Confirm Password")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    HStack {
                        if isConfirmPasswordVisible {
                            TextField("Re-enter password", text: $viewModel.confirmPassword)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Re-enter password", text: $viewModel.confirmPassword)
                        }

                        Button {
                            isConfirmPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel(isConfirmPasswordVisible ? "Hide confirm password" : "Show confirm password")
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Error & Success Banners

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    private func successBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.green)
            Spacer()
        }
        .padding(12)
        .background(Color.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    if viewModel.activeScreen == .firstTimeSetup {
                        await viewModel.setupFirstTimeCredentials()
                    } else {
                        await viewModel.login()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(buttonTitle)
                        .bold()
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isLoading)
        }
    }

    private var buttonTitle: String {
        if viewModel.isLoading {
            return "Verifying..."
        }
        return viewModel.activeScreen == .firstTimeSetup ? "Save & Unlock" : "Log In"
    }

    // MARK: - Mode Switch

    private var modeSwitchSection: some View {
        VStack(spacing: 8) {
            if viewModel.hasExistingCredentials {
                Button {
                    if viewModel.activeScreen == .manualLogin {
                        viewModel.activeScreen = .firstTimeSetup
                    } else {
                        viewModel.activeScreen = .manualLogin
                    }
                    viewModel.errorMessage = nil
                } label: {
                    Text(viewModel.activeScreen == .firstTimeSetup ? "Already have credentials? Log In" : "Reset / Update Credentials")
                        .font(.footnote)
                        .foregroundStyle(Color.accentColor)
                }
            }

            Button {
                viewModel.returnToBiometricScreen()
                dismiss()
            } label: {
                Label("Use Face ID Instead", systemImage: "faceid")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
    }
}

#Preview {
    LoginView(viewModel: AuthenticationViewModel())
}

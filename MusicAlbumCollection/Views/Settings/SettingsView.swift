import SwiftUI

/// Settings view providing collection management, preferences, and authentication controls.
struct SettingsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var albumVM: AlbumViewModel

    @State private var showingResetAlert = false
    @State private var showingLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    HStack {
                        Label("Current User", systemImage: "person.circle.fill")
                        Spacer()
                        Text(auth.username.isEmpty ? "Administrator" : auth.username)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Biometrics", systemImage: auth.biometricIconName)
                        Spacer()
                        Text(auth.biometricDisplayName)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Keychain Security", systemImage: "key.fill")
                        Spacer()
                        Text(auth.hasExistingCredentials ? "Enrolled" : "Not configured")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Collection Stats") {
                    HStack {
                        Label("Total Albums", systemImage: "opticaldisc")
                        Spacer()
                        Text("\(albumVM.totalAlbums)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Total Artists", systemImage: "person.2")
                        Spacer()
                        Text("\(albumVM.totalArtists)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Favourites", systemImage: "heart")
                        Spacer()
                        Text("\(albumVM.favouriteAlbums.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Data Management") {
                    Button(role: .destructive) {
                        showingResetAlert = true
                    } label: {
                        Label("Reset to Sample Albums", systemImage: "arrow.counterclockwise")
                    }
                }

                Section("About") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingLogoutConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Log Out")
                                .bold()
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Collection?", isPresented: $showingResetAlert) {
                Button("Reset", role: .destructive) {
                    albumVM.resetToSampleData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will replace current albums with the default sample collection.")
            }
            .confirmationDialog(
                "Are you sure you want to log out?",
                isPresented: $showingLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Log Out", role: .destructive) {
                    auth.logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will be required to authenticate with Face ID or password before accessing the collection again.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
        .environmentObject(AlbumViewModel())
}

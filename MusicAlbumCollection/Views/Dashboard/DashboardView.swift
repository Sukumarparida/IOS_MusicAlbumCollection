import SwiftUI

/// Modern, professional music collection dashboard displaying library stats, highlights, and quick actions.
struct DashboardView: View {
    @EnvironmentObject var albumVM: AlbumViewModel
    @EnvironmentObject var auth: AuthViewModel

    @StateObject private var viewModel = DashboardViewModel()

    @State private var showingAddAlbumSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    // DASHBOARD SECTION 1: HEADER
                    headerSection

                    // Empty state banner when library has zero albums
                    if !viewModel.hasAlbums {
                        emptyCollectionCard
                    }

                    // DASHBOARD SECTION 2: COLLECTION STATISTICS
                    statisticsSection

                    // DASHBOARD SECTION 3: RECENTLY ADDED
                    RecentAlbumSection(albums: viewModel.recentlyAdded)

                    // DASHBOARD SECTION 4: TOP LISTENED ALBUMS
                    TopListenedSection(albums: viewModel.topListened)

                    // DASHBOARD SECTION 5: QUICK ACTIONS
                    quickActionsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettingsSheet = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingLogoutConfirmation = true
                    } label: {
                        Text("Logout")
                            .font(.subheadline)
                    }
                }
            }
            .sheet(isPresented: $showingAddAlbumSheet) {
                AlbumFormView(albumToEdit: nil)
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
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
                Text("You will need to authenticate again with Face ID or password to access your collection.")
            }
            .navigationDestination(for: UUID.self) { id in
                AlbumDetailView(albumID: id)
            }
            .onAppear {
                viewModel.bind(to: albumVM)
            }
            .onChange(of: albumVM.albums) { _, newAlbums in
                viewModel.update(with: newAlbums)
            }
        }
    }

    // MARK: - DASHBOARD SECTION 1: HEADER

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Music Album Collection")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .textCase(.uppercase)
                    .foregroundStyle(.tint)
                    .tracking(1.0)

                Text("Welcome back, \(auth.username.isEmpty ? "Collector" : auth.username)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Button {
                showingSettingsSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.7), Color.blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.blue.opacity(0.2), radius: 6, y: 2)

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .accessibilityLabel("User profile and settings")
        }
        .padding(.vertical, 4)
    }

    // MARK: - DASHBOARD SECTION 2: COLLECTION STATISTICS

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Collection Overview")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                StatCardView(
                    title: "Total Albums",
                    value: viewModel.totalAlbums,
                    icon: "opticaldisc.fill",
                    accentColor: .purple
                )

                StatCardView(
                    title: "Total Artists",
                    value: viewModel.totalArtists,
                    icon: "person.2.fill",
                    accentColor: .blue
                )

                StatCardView(
                    title: "Favourite Albums",
                    value: viewModel.favouriteCount,
                    icon: "heart.fill",
                    accentColor: .pink
                )

                StatCardView(
                    title: "Total Tracks",
                    value: viewModel.totalTracks,
                    icon: "music.note.list",
                    accentColor: .teal
                )
            }
        }
    }

    // MARK: - DASHBOARD SECTION 5: QUICK ACTIONS

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)

            HStack(spacing: 12) {
                Button {
                    showingAddAlbumSheet = true
                } label: {
                    quickActionCard(
                        title: "Add Album",
                        subtitle: "New entry",
                        icon: "plus.circle.fill",
                        color: .purple
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    AlbumListView(favouritesOnly: false)
                } label: {
                    quickActionCard(
                        title: "Browse Albums",
                        subtitle: "Full collection",
                        icon: "square.grid.2x2.fill",
                        color: .blue
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    FavouriteView()
                } label: {
                    quickActionCard(
                        title: "View Favourites",
                        subtitle: "Starred records",
                        icon: "heart.fill",
                        color: .pink
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func quickActionCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Empty State Card

    private var emptyCollectionCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "music.note.house.fill")
                .font(.system(size: 44))
                .foregroundStyle(.tint)

            VStack(spacing: 4) {
                Text("Your Library is Waiting")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Start cataloguing your albums and tracking your favorite tracks today.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingAddAlbumSheet = true
            } label: {
                Label("Add Your First Album", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
        .environmentObject(AlbumViewModel())
}

import SwiftUI

/// Full details of one album, with favourite, listened, edit, and delete actions.
struct AlbumDetailView: View {
    @EnvironmentObject var albumVM: AlbumViewModel
    @Environment(\.dismiss) private var dismiss

    let albumID: UUID

    @State private var showingEdit = false
    @State private var showingDeleteAlert = false
    @State private var isProcessingListen = false
    @State private var justRecordedListen = false

    var body: some View {
        Group {
            if let album = albumVM.album(withID: albumID) {
                content(for: album)
            } else {
                Text("Album not found")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Album Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The main screen content for a found album.
    private func content(for album: Album) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Artwork & Titles
                VStack(spacing: 8) {
                    artworkView(for: album)
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)

                    Text(album.name)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)

                    Text(album.artist)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                // Metadata Rows
                VStack(spacing: 0) {
                    row("Genre", album.genre.rawValue)
                    Divider()
                    row("Release Year", String(album.releaseYear))
                    Divider()
                    row("Music Director", album.musicDirector.isEmpty ? "-" : album.musicDirector)
                    Divider()
                    row("Tracks", String(album.trackCount))
                    Divider()
                    row("Favourite Track", album.favouriteTrack.isEmpty ? "-" : album.favouriteTrack)
                    Divider()
                    listenCountRow(count: album.listenCount)
                }
                .padding(.horizontal)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)

                // Notes Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes").font(.headline)
                    Text(album.notes.isEmpty ? "No notes." : album.notes)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)

                // Action Buttons: Listened & Favourite
                HStack(spacing: 12) {
                    Button {
                        recordListenAction(for: album)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: justRecordedListen ? "checkmark.circle.fill" : "headphones")
                            Text(justRecordedListen ? "Recorded (+1)!" : "Listened")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(justRecordedListen ? .green : .accentColor)
                    .disabled(isProcessingListen)

                    Button {
                        toggleFavouriteAction(for: album)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: album.isFavourite ? "heart.fill" : "heart")
                                .foregroundStyle(album.isFavourite ? .pink : .primary)
                            Text(album.isFavourite ? "Favourited" : "Favourite")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)

                // Delete Button
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Album", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(16)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button {
                        toggleFavouriteAction(for: album)
                    } label: {
                        Image(systemName: album.isFavourite ? "heart.fill" : "heart")
                            .foregroundStyle(album.isFavourite ? .pink : .primary)
                    }
                    .accessibilityLabel(album.isFavourite ? "Remove from favourites" : "Mark as favourite")

                    Button("Edit") {
                        showingEdit = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AlbumFormView(albumToEdit: album)
        }
        .alert("Delete this album?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                albumVM.deleteAlbum(album)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: - Subviews & Rows

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 11)
    }

    private func listenCountRow(count: Int) -> some View {
        HStack {
            Label("Listen Count", systemImage: "headphones")
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(count)")
                .fontWeight(.bold)
                .contentTransition(.numericText())
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 11)
    }

    @ViewBuilder
    private func artworkView(for album: Album) -> some View {
        if let artworkID = album.artworkIdentifier, !artworkID.isEmpty {
            Image(artworkID)
                .resizable()
                .scaledToFill()
        } else {
            stylizedVinylPlaceholder(for: album)
        }
    }

    private func stylizedVinylPlaceholder(for album: Album) -> some View {
        ZStack {
            genreGradient(for: album.genre)

            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .frame(width: 110, height: 110)

            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .frame(width: 80, height: 80)

            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 50, height: 50)

            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 38, height: 38)

            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 10, height: 10)
        }
    }

    private func genreGradient(for genre: Genre) -> LinearGradient {
        let colors: [Color] = {
            switch genre {
            case .classical:
                return [Color(red: 0.16, green: 0.23, blue: 0.42), Color(red: 0.35, green: 0.47, blue: 0.72)]
            case .film:
                return [Color(red: 0.42, green: 0.16, blue: 0.48), Color(red: 0.76, green: 0.32, blue: 0.58)]
            case .rock:
                return [Color(red: 0.22, green: 0.15, blue: 0.22), Color(red: 0.65, green: 0.24, blue: 0.22)]
            case .pop:
                return [Color(red: 0.85, green: 0.25, blue: 0.48), Color(red: 0.98, green: 0.55, blue: 0.40)]
            case .folk:
                return [Color(red: 0.28, green: 0.45, blue: 0.32), Color(red: 0.62, green: 0.72, blue: 0.42)]
            case .devotional:
                return [Color(red: 0.85, green: 0.45, blue: 0.15), Color(red: 0.95, green: 0.72, blue: 0.25)]
            case .other:
                return [Color(red: 0.18, green: 0.35, blue: 0.55), Color(red: 0.35, green: 0.65, blue: 0.75)]
            }
        }()
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: - Actions

    /// Records a listen with responsive visual and haptic feedback, preventing accidental rapid double taps.
    private func recordListenAction(for album: Album) {
        guard !isProcessingListen else { return }
        isProcessingListen = true
        justRecordedListen = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            albumVM.incrementListenCount(album)
        }

        Task {
            try? await Task.sleep(nanoseconds: 750_000_000)
            withAnimation {
                justRecordedListen = false
                isProcessingListen = false
            }
        }
    }

    /// Toggles the album favourite flag with responsive haptic feedback and persistence.
    private func toggleFavouriteAction(for album: Album) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            albumVM.toggleFavourite(album)
        }
    }
}

#Preview {
    NavigationStack {
        AlbumDetailView(albumID: UUID())
    }
    .environmentObject(AlbumViewModel())
}

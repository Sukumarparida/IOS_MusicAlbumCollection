import SwiftUI

/// Full details of one album, presenting all metadata including artwork, date added, listen count,
/// and providing edit, delete, favourite, and listened actions.
struct AlbumDetailView: View {
    @EnvironmentObject var albumVM: AlbumViewModel
    @Environment(\.dismiss) private var dismiss

    let albumID: UUID
    @StateObject private var viewModel: AlbumDetailViewModel

    /// Initializes AlbumDetailView with the album's UUID.
    /// - Parameter albumID: The unique identifier of the album.
    init(albumID: UUID) {
        self.albumID = albumID
        _viewModel = StateObject(wrappedValue: AlbumDetailViewModel(albumID: albumID))
    }

    var body: some View {
        Group {
            if let album = viewModel.album {
                content(for: album)
            } else {
                Text("Album not found")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Album Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.bind(to: albumVM)
        }
    }

    // MARK: - Main Screen Content

    private func content(for album: Album) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Artwork & Titles
                VStack(spacing: 10) {
                    artworkView
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: Color.black.opacity(0.14), radius: 10, x: 0, y: 4)

                    Text(viewModel.name)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text(viewModel.artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                // Metadata Rows
                VStack(spacing: 0) {
                    row("Genre", viewModel.genreName)
                    Divider()
                    row("Release Year", viewModel.releaseYearString)
                    Divider()
                    row("Music Director", viewModel.musicDirector)
                    Divider()
                    row("Number of Tracks", viewModel.trackCountString)
                    Divider()
                    row("Favourite Track", viewModel.favouriteTrack)
                    Divider()
                    favouriteStatusRow(isFav: viewModel.isFavourite)
                    Divider()
                    listenCountRow(count: viewModel.listenCount)
                    Divider()
                    row("Date Added", viewModel.formattedDateAdded)
                }
                .padding(.horizontal)
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)

                // Notes Section
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.headline)
                    Text(viewModel.notes)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 4)

                // Action Buttons: Listened & Favourite
                HStack(spacing: 12) {
                    Button {
                        viewModel.recordListen()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.justRecordedListen ? "checkmark.circle.fill" : "headphones")
                            Text(viewModel.justRecordedListen ? "Recorded (+1)!" : "Listened")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(viewModel.justRecordedListen ? .green : .accentColor)
                    .disabled(viewModel.isProcessingListen)

                    Button {
                        viewModel.toggleFavourite()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.isFavourite ? "heart.fill" : "heart")
                                .foregroundStyle(viewModel.isFavourite ? .pink : .primary)
                            Text(viewModel.isFavourite ? "Favourited" : "Favourite")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.large)

                // Delete Button with Confirmation
                Button(role: .destructive) {
                    viewModel.showingDeleteAlert = true
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
                        viewModel.toggleFavourite()
                    } label: {
                        Image(systemName: viewModel.isFavourite ? "heart.fill" : "heart")
                            .foregroundStyle(viewModel.isFavourite ? .pink : .primary)
                    }
                    .accessibilityLabel(viewModel.isFavourite ? "Remove from favourites" : "Mark as favourite")

                    Button("Edit") {
                        viewModel.showingEditSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showingEditSheet) {
            EditAlbumView(album: album)
        }
        .deleteAlbumConfirmation(
            isPresented: $viewModel.showingDeleteAlert,
            albumName: viewModel.name
        ) {
            viewModel.deleteAlbum()
            dismiss()
        }
    }

    // MARK: - Subviews & Rows

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 11)
    }

    private func favouriteStatusRow(isFav: Bool) -> some View {
        HStack {
            Text("Favourite Status")
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: isFav ? "heart.fill" : "heart")
                    .foregroundStyle(isFav ? .pink : .secondary)
                Text(isFav ? "Yes" : "No")
                    .fontWeight(.medium)
            }
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
    private var artworkView: some View {
        if let artworkID = viewModel.artworkIdentifier, !artworkID.isEmpty {
            if let presetGradient = presetGradient(for: artworkID) {
                ZStack {
                    presetGradient
                    Image(systemName: presetIcon(for: artworkID))
                        .font(.system(size: 48))
                        .foregroundStyle(.white)
                }
            } else {
                Image(artworkID)
                    .resizable()
                    .scaledToFill()
            }
        } else {
            stylizedVinylPlaceholder
        }
    }

    private var stylizedVinylPlaceholder: some View {
        ZStack {
            genreGradient(for: viewModel.genre)

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

    private func presetGradient(for preset: String) -> LinearGradient? {
        switch preset {
        case "vinyl_classic":
            return LinearGradient(colors: [Color.black, Color.gray], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "vinyl_gold":
            return LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "vinyl_neon":
            return LinearGradient(colors: [Color.purple, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "vinyl_retro":
            return LinearGradient(colors: [Color.brown, Color.orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return nil
        }
    }

    private func presetIcon(for preset: String) -> String {
        switch preset {
        case "vinyl_classic": return "music.note"
        case "vinyl_gold": return "star.fill"
        case "vinyl_neon": return "sparkles"
        case "vinyl_retro": return "guitars"
        default: return "opticaldisc"
        }
    }
}

#Preview {
    NavigationStack {
        AlbumDetailView(albumID: UUID())
    }
    .environmentObject(AlbumViewModel())
}

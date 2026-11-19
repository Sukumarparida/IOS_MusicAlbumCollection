import SwiftUI

/// A card displaying an album's artwork, name, artist, genre badge, release year, and interactive favourite toggle.
struct AlbumCardView: View {
    @EnvironmentObject var albumVM: AlbumViewModel
    let album: Album

    var body: some View {
        HStack(spacing: 14) {
            // Album Artwork Thumbnail
            artworkThumbnail
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Album Metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(album.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(album.genre.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())

                    Text(String(album.releaseYear))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Favourite Indicator & Button
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    albumVM.toggleFavourite(album)
                }
            } label: {
                Image(systemName: album.isFavourite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(album.isFavourite ? .pink : .secondary)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(album.isFavourite ? "Remove from favourites" : "Mark as favourite")
        }
        .padding(AppConstants.UI.cardPadding)
        .cardStyle()
    }

    // MARK: - Artwork Subviews

    @ViewBuilder
    private var artworkThumbnail: some View {
        if let artworkID = album.artworkIdentifier, !artworkID.isEmpty {
            if let presetGradient = presetGradient(for: artworkID) {
                ZStack {
                    presetGradient
                    Image(systemName: presetIcon(for: artworkID))
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            } else {
                Image(artworkID)
                    .resizable()
                    .scaledToFill()
            }
        } else {
            stylizedVinylThumbnail
        }
    }

    private var stylizedVinylThumbnail: some View {
        ZStack {
            genreGradient(for: album.genre)

            // Vinyl grooves
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .frame(width: 42, height: 42)

            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .frame(width: 28, height: 28)

            // Center spindle hole
            Circle()
                .fill(Color.black.opacity(0.35))
                .frame(width: 16, height: 16)

            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 5, height: 5)
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
    AlbumCardView(
        album: Album(
            name: "Roja",
            artist: "A. R. Rahman",
            genre: .film,
            releaseYear: 1992,
            musicDirector: "A. R. Rahman",
            trackCount: 6,
            isFavourite: true
        )
    )
    .environmentObject(AlbumViewModel())
    .padding()
}

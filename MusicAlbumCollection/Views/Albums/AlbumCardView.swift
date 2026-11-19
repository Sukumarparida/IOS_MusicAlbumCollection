import SwiftUI

/// A card displaying an album's name, artist, genre badge, release year, and interactive favourite toggle.
struct AlbumCardView: View {
    @EnvironmentObject var albumVM: AlbumViewModel
    let album: Album

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "opticaldisc.fill")
                .font(.largeTitle)
                .foregroundStyle(.tint)
                .frame(width: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.headline)
                Text(album.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Text(album.genre.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                    Text(String(album.releaseYear))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    albumVM.toggleFavourite(album)
                }
            } label: {
                Image(systemName: album.isFavourite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(album.isFavourite ? .pink : .secondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(album.isFavourite ? "Remove from favourites" : "Mark as favourite")
        }
        .padding(AppConstants.UI.cardPadding)
        .cardStyle()
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

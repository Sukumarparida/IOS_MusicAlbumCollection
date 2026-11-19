import SwiftUI

/// Compact album card used in horizontal rows and collections.
struct MiniAlbumCardView: View {
    let album: Album
    let showListens: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "opticaldisc.fill")
                .font(.title)
                .foregroundStyle(.tint)
            Text(album.name)
                .font(.headline)
                .lineLimit(1)
            Text(album.artist)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(showListens ? "\(album.listenCount) listens" : album.genre.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(AppConstants.UI.cardPadding)
        .frame(width: AppConstants.UI.miniCardWidth, alignment: .leading)
        .cardStyle()
    }
}

#Preview {
    MiniAlbumCardView(
        album: Album(
            name: "Abbey Road",
            artist: "The Beatles",
            genre: .rock,
            releaseYear: 1969,
            musicDirector: "George Martin",
            trackCount: 17
        ),
        showListens: true
    )
    .padding()
}

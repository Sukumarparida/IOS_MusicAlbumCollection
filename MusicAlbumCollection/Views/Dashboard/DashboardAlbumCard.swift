import SwiftUI

/// Style variant for DashboardAlbumCard indicating which secondary metric to emphasize.
enum DashboardCardStyle {
    case recent
    case topListened
}

/// An attractive, modern album card designed for horizontal dashboard carousels.
struct DashboardAlbumCard: View {
    let album: Album
    var style: DashboardCardStyle = .recent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            artworkView
                .frame(width: 148, height: 148)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                Text(album.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    switch style {
                    case .recent:
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(album.releaseYear))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(album.genre.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                    case .topListened:
                        Image(systemName: "headphones")
                            .font(.caption2)
                            .foregroundStyle(.tint)
                        Text("\(album.listenCount) \(album.listenCount == 1 ? "listen" : "listens")")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tint)
                    }
                }
                .padding(.top, 2)
            }
            .frame(width: 148, alignment: .leading)
        }
        .padding(10)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Artwork

    @ViewBuilder
    private var artworkView: some View {
        if let artworkID = album.artworkIdentifier, !artworkID.isEmpty {
            Image(artworkID)
                .resizable()
                .scaledToFill()
        } else {
            stylizedArtwork
        }
    }

    private var stylizedArtwork: some View {
        ZStack {
            genreGradient

            // Vinyl record circular grooves overlay
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .frame(width: 120, height: 120)

            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .frame(width: 90, height: 90)

            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 60, height: 60)

            // Center spindle disc
            Circle()
                .fill(Color.black.opacity(0.28))
                .frame(width: 44, height: 44)

            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 12, height: 12)

            // Genre icon badge
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: genreIcon(for: album.genre))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.4), in: Circle())
                        .padding(8)
                }
            }
        }
    }

    private var genreGradient: LinearGradient {
        let colors: [Color] = {
            switch album.genre {
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

    private func genreIcon(for genre: Genre) -> String {
        switch genre {
        case .classical: return "pianokeys"
        case .film: return "film"
        case .rock: return "guitars"
        case .pop: return "sparkles"
        case .folk: return "leaf.fill"
        case .devotional: return "sun.max.fill"
        case .other: return "music.note"
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        DashboardAlbumCard(
            album: Album(
                name: "Abbey Road",
                artist: "The Beatles",
                genre: .rock,
                releaseYear: 1969,
                musicDirector: "George Martin",
                trackCount: 17,
                listenCount: 24
            ),
            style: .recent
        )
        DashboardAlbumCard(
            album: Album(
                name: "Roja",
                artist: "A. R. Rahman",
                genre: .film,
                releaseYear: 1992,
                musicDirector: "A. R. Rahman",
                trackCount: 6,
                listenCount: 42
            ),
            style: .topListened
        )
    }
    .padding()
}

import SwiftUI

/// Section displaying up to five albums with the highest listen counts in descending order.
struct TopListenedSection: View {
    let albums: [Album]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerView

            if albums.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 14) {
                        ForEach(Array(albums.prefix(5).enumerated()), id: \.element.id) { index, album in
                            NavigationLink(value: album.id) {
                                TopListenedCard(album: album, rank: index + 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text("Top Listened Albums")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Image(systemName: "flame.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }

            Text("Your 5 most played records on repeat")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "headphones")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("No Listened Albums Yet")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Tap 'Listened' on an album's detail page to track your plays.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

/// Specialized card view for top-listened albums displaying rank and verified listen count.
struct TopListenedCard: View {
    let album: Album
    let rank: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                artworkView
                    .frame(width: 148, height: 148)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)

                rankBadge
                    .padding(8)
            }

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
                    Image(systemName: "headphones")
                        .font(.caption2)
                        .foregroundStyle(.tint)
                    Text("\(album.listenCount) \(album.listenCount == 1 ? "listen" : "listens")")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
                .padding(.top, 2)
            }
            .frame(width: 148, alignment: .leading)
        }
        .padding(10)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Rank Badge

    private var rankBadge: some View {
        HStack(spacing: 2) {
            if rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.yellow)
            }
            Text("#\(rank)")
                .font(.caption2.weight(.heavy))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(rankBadgeBackground, in: Capsule())
        .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
    }

    private var rankBadgeBackground: AnyShapeStyle {
        switch rank {
        case 1:
            return AnyShapeStyle(LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
        case 2:
            return AnyShapeStyle(LinearGradient(colors: [Color.gray, Color.secondary], startPoint: .topLeading, endPoint: .bottomTrailing))
        case 3:
            return AnyShapeStyle(LinearGradient(colors: [Color.brown, Color.orange.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
        default:
            return AnyShapeStyle(LinearGradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
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

            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                .frame(width: 120, height: 120)

            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .frame(width: 90, height: 90)

            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                .frame(width: 60, height: 60)

            Circle()
                .fill(Color.black.opacity(0.28))
                .frame(width: 44, height: 44)

            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 12, height: 12)
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
}

#Preview {
    NavigationStack {
        TopListenedSection(
            albums: [
                Album(
                    name: "Thriller",
                    artist: "Michael Jackson",
                    genre: .pop,
                    releaseYear: 1982,
                    musicDirector: "Quincy Jones",
                    trackCount: 9,
                    listenCount: 37
                ),
                Album(
                    name: "Abbey Road",
                    artist: "The Beatles",
                    genre: .rock,
                    releaseYear: 1969,
                    musicDirector: "George Martin",
                    trackCount: 17,
                    listenCount: 24
                )
            ]
        )
        .padding()
    }
}

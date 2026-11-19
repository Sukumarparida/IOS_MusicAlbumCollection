import SwiftUI

/// Section displaying the five most recently added albums with a View All action.
struct RecentAlbumSection: View {
    let albums: [Album]
    var onViewAll: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recently Added")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)

                    Text("Latest additions to your shelf")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !albums.isEmpty {
                    NavigationLink {
                        AlbumListView(favouritesOnly: false)
                    } label: {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.tint)
                    }
                }
            }

            if albums.isEmpty {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 14) {
                        ForEach(albums) { album in
                            NavigationLink(value: album.id) {
                                DashboardAlbumCard(album: album, style: .recent)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: "opticaldisc")
                    .font(.title3)
                    .foregroundStyle(.tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("No Albums Yet")
                    .font(.subheadline.weight(.semibold))
                Text("Add your first album using the quick actions below.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        RecentAlbumSection(
            albums: [
                Album(
                    name: "Roja",
                    artist: "A. R. Rahman",
                    genre: .film,
                    releaseYear: 1992,
                    musicDirector: "A. R. Rahman",
                    trackCount: 6
                )
            ]
        )
        .padding()
    }
}

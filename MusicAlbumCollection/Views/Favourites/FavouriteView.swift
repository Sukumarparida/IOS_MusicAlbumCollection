import SwiftUI

/// Dedicated screen displaying the user's favourite music albums with search, filtering, and quick actions.
struct FavouriteView: View {
    @EnvironmentObject var albumVM: AlbumViewModel
    @StateObject private var viewModel = FavouriteViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.favouriteAlbums.isEmpty {
                    emptyFavouritesState
                } else if viewModel.filteredFavourites.isEmpty {
                    emptySearchState
                } else {
                    favouriteListContent
                }
            }
            .navigationTitle("Favourites")
            .searchable(text: $viewModel.searchText, prompt: "Search favourite albums or artists")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    genreFilterMenu
                }

                if !viewModel.favouriteAlbums.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        statsSummaryBadge
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                AlbumDetailView(albumID: id)
            }
            .onAppear {
                viewModel.bind(to: albumVM)
            }
            .onChange(of: albumVM.albums) { _, _ in
                viewModel.bind(to: albumVM)
            }
        }
    }

    // MARK: - List Content

    private var favouriteListContent: some View {
        List {
            ForEach(viewModel.filteredFavourites) { album in
                NavigationLink(value: album.id) {
                    FavouriteAlbumRow(album: album) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            viewModel.toggleFavourite(id: album.id)
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation {
                            viewModel.removeFavourite(id: album.id)
                        }
                    } label: {
                        Label("Remove", systemImage: "heart.slash.fill")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Toolbar Controls

    private var genreFilterMenu: some View {
        Menu {
            Button {
                viewModel.selectedGenre = nil
            } label: {
                HStack {
                    Text("All Genres")
                    if viewModel.selectedGenre == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(Genre.allCases) { genre in
                Button {
                    viewModel.selectedGenre = genre
                } label: {
                    HStack {
                        Text(genre.rawValue)
                        if viewModel.selectedGenre == genre {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label(
                "Filter",
                systemImage: viewModel.selectedGenre == nil
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
        }
    }

    private var statsSummaryBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .font(.caption2)
                .foregroundStyle(.pink)
            Text("\(viewModel.totalFavourites)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.pink.opacity(0.12), in: Capsule())
    }

    // MARK: - Empty States

    private var emptyFavouritesState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.pink.opacity(0.2), Color.purple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)

                Image(systemName: "heart.slash")
                    .font(.system(size: 42))
                    .foregroundStyle(.pink)
            }

            VStack(spacing: 6) {
                Text("No Favourites Yet")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Text("Tap the heart icon on any album in your collection to add it to your favourites.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var emptySearchState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("No Matching Favourites")
                    .font(.title3.weight(.bold))
                Text("No favourite albums match '\(viewModel.searchText)'.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button("Clear Filter") {
                viewModel.searchText = ""
                viewModel.selectedGenre = nil
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

/// Attractive card view presenting an individual favourite album entry.
struct FavouriteAlbumRow: View {
    let album: Album
    let onToggleFavourite: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            artworkView
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(album.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(album.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(album.genre.rawValue)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())

                    Text(String(album.releaseYear))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 3) {
                        Image(systemName: "headphones")
                            .font(.caption2)
                        Text("\(album.listenCount)")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onToggleFavourite()
            } label: {
                Image(systemName: album.isFavourite ? "heart.fill" : "heart")
                    .font(.system(size: 20))
                    .foregroundStyle(album.isFavourite ? .pink : .secondary)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(album.isFavourite ? "Remove from favourites" : "Add to favourites")
        }
        .padding(12)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Artwork

    @ViewBuilder
    private var artworkView: some View {
        if let artworkID = album.artworkIdentifier, !artworkID.isEmpty {
            Image(artworkID)
                .resizable()
                .scaledToFill()
        } else {
            vinylPlaceholder
        }
    }

    private var vinylPlaceholder: some View {
        ZStack {
            genreGradient

            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .frame(width: 52, height: 52)

            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .frame(width: 36, height: 36)

            Circle()
                .fill(Color.black.opacity(0.35))
                .frame(width: 22, height: 22)

            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 6, height: 6)
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
    FavouriteView()
        .environmentObject(AlbumViewModel())
}

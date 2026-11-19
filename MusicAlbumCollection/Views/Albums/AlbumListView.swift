import SwiftUI

/// Displays a list of albums (all albums or favourites only) with search, genre filtering, and album creation.
struct AlbumListView: View {
    @EnvironmentObject var albumVM: AlbumViewModel
    var favouritesOnly: Bool = false

    @State private var showingAddSheet = false

    private var title: String {
        favouritesOnly ? "Favourites" : "Albums"
    }

    private var displayedAlbums: [Album] {
        if favouritesOnly {
            return albumVM.filteredAlbums.filter { $0.isFavourite }
        } else {
            return albumVM.filteredAlbums
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if displayedAlbums.isEmpty {
                    emptyView
                } else {
                    List {
                        ForEach(displayedAlbums) { album in
                            NavigationLink(value: album.id) {
                                AlbumCardView(album: album)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        .onDelete { offsets in
                            albumVM.deleteAlbums(at: offsets, from: displayedAlbums)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(title)
            .searchable(text: $albumVM.searchText, prompt: "Search albums or artists")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    genreFilterMenu
                }

                if !favouritesOnly {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AlbumFormView(albumToEdit: nil)
            }
            .navigationDestination(for: UUID.self) { id in
                AlbumDetailView(albumID: id)
            }
        }
    }

    // MARK: - Subviews

    private var genreFilterMenu: some View {
        Menu {
            Button {
                albumVM.selectedGenre = nil
            } label: {
                HStack {
                    Text("All Genres")
                    if albumVM.selectedGenre == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(Genre.allCases) { genre in
                Button {
                    albumVM.selectedGenre = genre
                } label: {
                    HStack {
                        Text(genre.rawValue)
                        if albumVM.selectedGenre == genre {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label(
                "Filter",
                systemImage: albumVM.selectedGenre == nil
                    ? "line.3.horizontal.decrease.circle"
                    : "line.3.horizontal.decrease.circle.fill"
            )
        }
    }

    private var emptyView: some View {
        EmptyStateView(
            title: emptyTitle,
            systemImage: emptyIcon,
            description: emptyDescription
        )
    }

    private var emptyTitle: String {
        if !albumVM.searchText.isEmpty || albumVM.selectedGenre != nil {
            return "No Results"
        }
        return favouritesOnly ? "No Favourites Yet" : "No Albums"
    }

    private var emptyIcon: String {
        if !albumVM.searchText.isEmpty || albumVM.selectedGenre != nil {
            return "magnifyingglass"
        }
        return favouritesOnly ? "heart.slash" : "music.note"
    }

    private var emptyDescription: String {
        if !albumVM.searchText.isEmpty || albumVM.selectedGenre != nil {
            return "Try adjusting your search or genre filter."
        }
        return favouritesOnly
            ? "Tap the heart icon on any album to add it to your favourites."
            : "Tap the '+' button above to add your first album."
    }
}

#Preview("All Albums") {
    AlbumListView(favouritesOnly: false)
        .environmentObject(AlbumViewModel())
}

#Preview("Favourites") {
    AlbumListView(favouritesOnly: true)
        .environmentObject(AlbumViewModel())
}

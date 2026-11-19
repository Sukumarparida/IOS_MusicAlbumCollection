import SwiftUI

/// Displays a scrollable list of albums with search, genre filtering, swipe-to-delete, and album creation.
struct AlbumListView: View {
    @EnvironmentObject var albumVM: AlbumViewModel

    let favouritesOnly: Bool
    @StateObject private var viewModel: AlbumListViewModel

    /// Initializes AlbumListView with an optional favouritesOnly filter flag.
    /// - Parameter favouritesOnly: When true, restricts list strictly to starred albums.
    init(favouritesOnly: Bool = false) {
        self.favouritesOnly = favouritesOnly
        _viewModel = StateObject(wrappedValue: AlbumListViewModel(favouritesOnly: favouritesOnly))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isEmpty {
                    emptyView
                } else {
                    List {
                        ForEach(viewModel.displayedAlbums) { album in
                            NavigationLink(value: album.id) {
                                AlbumCardView(album: album)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        .onDelete { offsets in
                            viewModel.deleteAlbums(at: offsets)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .searchable(text: $viewModel.searchText, prompt: "Search albums or artists")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    genreFilterMenu
                }

                if !favouritesOnly {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.showingAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add Album")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                AddAlbumView()
            }
            .navigationDestination(for: UUID.self) { id in
                AlbumDetailView(albumID: id)
            }
            .onAppear {
                viewModel.bind(to: albumVM)
            }
        }
    }

    // MARK: - Subviews

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

    private var emptyView: some View {
        EmptyStateView(
            title: viewModel.emptyTitle,
            systemImage: viewModel.emptyIcon,
            description: viewModel.emptyDescription
        )
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

import SwiftUI
import Combine

/// View model managing the Favourites screen state, search query, genre filtering, and favourite toggling.
@MainActor
final class FavouriteViewModel: ObservableObject {
    @Published private(set) var favouriteAlbums: [Album] = []
    @Published var searchText: String = ""
    @Published var selectedGenre: Genre? = nil
    @Published var sortOption: AlbumSortOption = .recentlyAdded
    @Published var showingFilterSheet: Bool = false

    private let repository: AlbumRepository
    private weak var albumViewModel: AlbumViewModel?
    private var cancellables = Set<AnyCancellable>()

    /// Initializes the FavouriteViewModel with an album repository.
    /// - Parameter repository: Optional album repository; defaults to DefaultAlbumRepository.
    init(repository: AlbumRepository? = nil) {
        let repo = repository ?? DefaultAlbumRepository()
        self.repository = repo
        self.favouriteAlbums = repo.fetchAlbums().filter { $0.isFavourite }
    }

    /// Binds this view model to the shared AlbumViewModel to observe changes reactively and synchronously.
    /// - Parameter albumViewModel: The shared AlbumViewModel from environment.
    func bind(to albumViewModel: AlbumViewModel) {
        self.albumViewModel = albumViewModel
        cancellables.removeAll()
        albumViewModel.$albums
            .sink { [weak self] albums in
                self?.favouriteAlbums = albums.filter { $0.isFavourite }
            }
            .store(in: &cancellables)
        self.favouriteAlbums = albumViewModel.albums.filter { $0.isFavourite }
    }

    /// Returns the filtered and sorted list of favourite albums matching the search text and selected genre.
    var filteredFavourites: [Album] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = favouriteAlbums.filter { album in
            let matchesSearch = query.isEmpty
                || album.name.localizedCaseInsensitiveContains(query)
                || album.artist.localizedCaseInsensitiveContains(query)
            let matchesGenre = selectedGenre == nil || album.genre == selectedGenre
            return matchesSearch && matchesGenre
        }
        return sortOption.sort(albums: filtered)
    }

    /// Total count of favourite albums in the collection.
    var totalFavourites: Int {
        favouriteAlbums.count
    }

    /// Total number of plays recorded across all favourite albums.
    var totalListens: Int {
        favouriteAlbums.reduce(0) { $0 + max(0, $1.listenCount) }
    }

    /// Toggles the favourite status of an album by UUID using the central repository.
    /// - Parameter id: The unique identifier of the album.
    func toggleFavourite(id: UUID) {
        if let albumViewModel {
            albumViewModel.toggleFavourite(id: id)
        } else {
            repository.toggleFavourite(id: id)
            favouriteAlbums = repository.fetchAlbums().filter { $0.isFavourite }
        }
    }

    /// Removes an album from favourites.
    /// - Parameter id: The unique identifier of the album to remove from favourites.
    func removeFavourite(id: UUID) {
        if let album = repository.getAlbum(by: id), album.isFavourite {
            toggleFavourite(id: id)
        }
    }

    /// Removes favourite status from albums at specified offsets in a source list.
    /// - Parameters:
    ///   - offsets: IndexSet of items to remove.
    ///   - source: Source array of albums.
    func removeFavourites(at offsets: IndexSet, from source: [Album]) {
        for index in offsets {
            let album = source[index]
            if album.isFavourite {
                toggleFavourite(id: album.id)
            }
        }
    }
}

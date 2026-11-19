import SwiftUI
import Combine

/// View model managing album list display, search, filtering, and deletion operations.
@MainActor
final class AlbumListViewModel: ObservableObject {
    /// Search filter string for album title or artist.
    @Published var searchText: String = ""

    /// Selected genre filter; nil denotes all genres.
    @Published var selectedGenre: Genre? = nil

    /// Flag indicating whether the add album sheet is presented.
    @Published var showingAddSheet: Bool = false

    /// When true, only favourite albums are displayed in the list.
    let favouritesOnly: Bool

    /// Cached list of albums.
    @Published private(set) var albums: [Album] = []

    private let repository: AlbumRepository
    private weak var albumViewModel: AlbumViewModel?
    private var cancellables = Set<AnyCancellable>()

    /// Initializes the AlbumListViewModel.
    /// - Parameters:
    ///   - repository: Optional album repository; defaults to DefaultAlbumRepository.
    ///   - favouritesOnly: Whether this list is scoped strictly to favourite albums.
    init(repository: AlbumRepository? = nil, favouritesOnly: Bool = false) {
        let repo = repository ?? DefaultAlbumRepository()
        self.repository = repo
        self.favouritesOnly = favouritesOnly
        self.albums = repo.fetchAlbums()
    }

    /// Binds this view model to the shared AlbumViewModel to observe changes reactively.
    /// - Parameter albumViewModel: The shared AlbumViewModel from environment.
    func bind(to albumViewModel: AlbumViewModel) {
        self.albumViewModel = albumViewModel
        cancellables.removeAll()

        albumViewModel.$albums
            .sink { [weak self] newAlbums in
                self?.albums = newAlbums
            }
            .store(in: &cancellables)

        self.albums = albumViewModel.albums
    }

    /// Reloads the album list from the repository.
    func reload() {
        if let albumViewModel {
            self.albums = albumViewModel.albums
        } else {
            self.albums = repository.fetchAlbums()
        }
    }

    // MARK: - Computed Properties

    /// Albums matching search query, genre filter, and favourites filter.
    var displayedAlbums: [Album] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return albums.filter { album in
            let matchesSearch = query.isEmpty
                || album.name.localizedCaseInsensitiveContains(query)
                || album.artist.localizedCaseInsensitiveContains(query)

            let matchesGenre = selectedGenre == nil || album.genre == selectedGenre
            let matchesFav = !favouritesOnly || album.isFavourite

            return matchesSearch && matchesGenre && matchesFav
        }
    }

    /// Screen title based on mode.
    var navigationTitle: String {
        favouritesOnly ? "Favourites" : "Albums"
    }

    /// Whether displayed albums list is empty.
    var isEmpty: Bool {
        displayedAlbums.isEmpty
    }

    /// Title for the empty state view.
    var emptyTitle: String {
        if !searchText.isEmpty || selectedGenre != nil {
            return "No Results"
        }
        return favouritesOnly ? "No Favourites Yet" : "No Albums"
    }

    /// SF Symbol icon name for the empty state view.
    var emptyIcon: String {
        if !searchText.isEmpty || selectedGenre != nil {
            return "magnifyingglass"
        }
        return favouritesOnly ? "heart.slash" : "music.note"
    }

    /// Informational message for the empty state view.
    var emptyDescription: String {
        if !searchText.isEmpty || selectedGenre != nil {
            return "Try adjusting your search or genre filter."
        }
        return favouritesOnly
            ? "Tap the heart icon on any album to add it to your favourites."
            : "Tap the '+' button above to add your first album."
    }

    // MARK: - Actions

    /// Deletes albums matching selected offsets in the current displayed list.
    /// - Parameter offsets: The IndexSet of items to remove.
    func deleteAlbums(at offsets: IndexSet) {
        let targets = displayedAlbums
        let idsToDelete = offsets.map { targets[$0].id }

        if let albumViewModel {
            albumViewModel.deleteAlbums(at: offsets, from: targets)
        } else {
            repository.deleteAlbums(ids: idsToDelete)
            reload()
        }
    }

    /// Deletes a specific album from persistence.
    /// - Parameter album: The album to delete.
    func deleteAlbum(_ album: Album) {
        if let albumViewModel {
            albumViewModel.deleteAlbum(album)
        } else {
            repository.deleteAlbum(id: album.id)
            reload()
        }
    }

    /// Toggles the favourite status of an album.
    /// - Parameter album: The album whose status should toggle.
    func toggleFavourite(_ album: Album) {
        if let albumViewModel {
            albumViewModel.toggleFavourite(album)
        } else {
            repository.toggleFavourite(id: album.id)
            reload()
        }
    }
}

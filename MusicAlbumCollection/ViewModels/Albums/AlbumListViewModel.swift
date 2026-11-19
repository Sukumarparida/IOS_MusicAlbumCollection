import SwiftUI
import Combine

/// View model managing album list display, search, genre filtering, sorting, and deletion operations.
@MainActor
final class AlbumListViewModel: ObservableObject {
    /// Search filter string for album title or artist.
    @Published var searchText: String = ""

    /// Selected genre filter; nil denotes all genres.
    @Published var selectedGenre: Genre? = nil

    /// Active sorting option applied to displayed albums.
    @Published var sortOption: AlbumSortOption = .recentlyAdded

    /// Controls presentation of the filter and sort configuration sheet.
    @Published var showingFilterSheet: Bool = false

    /// Flag indicating whether the add album sheet is presented.
    @Published var showingAddSheet: Bool = false

    /// When true, only favourite albums are displayed in the list.
    let favouritesOnly: Bool

    /// Cached list of albums in their persisted repository order.
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

    // MARK: - Computed Filter & Sort Properties

    /// Encapsulated filter state reflecting the current search, genre, and sort settings.
    var filterState: AlbumFilterState {
        get {
            AlbumFilterState(
                searchText: searchText,
                selectedGenre: selectedGenre,
                sortOption: sortOption
            )
        }
        set {
            searchText = newValue.searchText
            selectedGenre = newValue.selectedGenre
            sortOption = newValue.sortOption
        }
    }

    /// Number of active filters (selected genre and non-default sorting).
    var activeFilterCount: Int {
        var count = 0
        if selectedGenre != nil { count += 1 }
        if sortOption != .recentlyAdded { count += 1 }
        return count
    }

    /// Whether any search query or genre filter is currently applied.
    var isSearchingOrFiltering: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedGenre != nil
    }

    /// Albums matching search query, genre filter, and favourites restriction, ordered by sortOption.
    /// Filtering and sorting operations produce a derived array and never alter stored album order.
    var displayedAlbums: [Album] {
        let baseAlbums = favouritesOnly ? albums.filter { $0.isFavourite } : albums
        return filterState.apply(to: baseAlbums)
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
        if isSearchingOrFiltering {
            return "No Results Found"
        }
        return favouritesOnly ? "No Favourites Yet" : "No Albums"
    }

    /// SF Symbol icon name for the empty state view.
    var emptyIcon: String {
        if isSearchingOrFiltering {
            return "magnifyingglass"
        }
        return favouritesOnly ? "heart.slash" : "music.note"
    }

    /// Informational message for the empty state view.
    var emptyDescription: String {
        let cleanQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanQuery.isEmpty && selectedGenre != nil {
            return "No \(selectedGenre?.rawValue ?? "") albums match \"\(cleanQuery)\"."
        } else if !cleanQuery.isEmpty {
            return "No albums match \"\(cleanQuery)\". Try searching by album or artist."
        } else if let genre = selectedGenre {
            return "No albums found in the \(genre.rawValue) genre."
        }
        return favouritesOnly
            ? "Tap the heart icon on any album to add it to your favourites."
            : "Tap the '+' button above to add your first album."
    }

    // MARK: - Actions

    /// Clears the active search query.
    func clearSearch() {
        searchText = ""
    }

    /// Clears only the genre filter and resets sorting to default.
    func clearFilters() {
        selectedGenre = nil
        sortOption = .recentlyAdded
    }

    /// Resets search, genre filter, and sorting to their initial states.
    func resetAll() {
        searchText = ""
        selectedGenre = nil
        sortOption = .recentlyAdded
    }

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

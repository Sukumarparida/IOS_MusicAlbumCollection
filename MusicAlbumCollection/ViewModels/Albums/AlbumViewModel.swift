import SwiftUI
import Combine

/// View model managing album presentation state, search, filtering, and CRUD operations.
@MainActor
final class AlbumViewModel: ObservableObject {
    @Published var albums: [Album] = []
    @Published var searchText = ""
    @Published var selectedGenre: Genre?

    private let repository: AlbumRepository
    private let listeningService: ListeningService

    /// Initializes AlbumViewModel with an album repository and listening service.
    /// - Parameter repository: The central album repository to interact with.
    init(repository: AlbumRepository? = nil) {
        let repo = repository ?? DefaultAlbumRepository()
        self.repository = repo
        self.listeningService = ListeningService(repository: repo)
        self.albums = repo.fetchAlbums()
    }

    /// Reloads the album list from the repository.
    func reload() {
        self.albums = repository.fetchAlbums()
    }

    // MARK: - Computed data for screens

    /// Albums matching the search query (name or artist) and selected genre filter.
    var filteredAlbums: [Album] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return albums.filter { album in
            let matchesSearch = query.isEmpty
                || album.name.localizedCaseInsensitiveContains(query)
                || album.artist.localizedCaseInsensitiveContains(query)
            let matchesGenre = selectedGenre == nil || album.genre == selectedGenre
            return matchesSearch && matchesGenre
        }
    }

    /// Total number of albums in the collection.
    var totalAlbums: Int {
        albums.count
    }

    /// Number of unique artists represented in the collection.
    var totalArtists: Int {
        Set(albums.map { $0.artist.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }).count
    }

    /// Total number of tracks across all albums in the collection.
    var totalTracks: Int {
        albums.reduce(0) { $0 + $1.trackCount }
    }

    /// Albums marked as favourite by the user.
    var favouriteAlbums: [Album] {
        albums.filter { $0.isFavourite }
    }

    /// The 5 most recently added albums.
    var recentlyAdded: [Album] {
        Array(albums.sorted { $0.dateAdded > $1.dateAdded }.prefix(5))
    }

    /// The 5 most listened albums (played at least once), consistently ordered by highest listen count.
    var topListened: [Album] {
        listeningService.topListened(from: albums, limit: 5)
    }

    /// Looks up the latest version of an album by UUID.
    /// - Parameter id: The unique UUID of the album.
    /// - Returns: The matched Album if found.
    func album(withID id: UUID) -> Album? {
        repository.getAlbum(by: id)
    }

    // MARK: - Actions

    /// Adds a new album to the collection.
    /// - Parameter album: The album to add.
    func addAlbum(_ album: Album) {
        repository.addAlbum(album)
        reload()
    }

    /// Updates an existing album.
    /// - Parameter album: The modified album to persist.
    func updateAlbum(_ album: Album) {
        repository.updateAlbum(album)
        reload()
    }

    /// Deletes a specific album.
    /// - Parameter album: The album instance to remove.
    func deleteAlbum(_ album: Album) {
        repository.deleteAlbum(id: album.id)
        reload()
    }

    /// Deletes an album by its unique UUID.
    /// - Parameter id: The UUID of the album to delete.
    func deleteAlbum(id: UUID) {
        repository.deleteAlbum(id: id)
        reload()
    }

    /// Deletes albums matching selected offsets in a source array.
    /// - Parameters:
    ///   - offsets: IndexSet of items to remove.
    ///   - source: Source array of albums.
    func deleteAlbums(at offsets: IndexSet, from source: [Album]) {
        let idsToDelete = offsets.map { source[$0].id }
        repository.deleteAlbums(ids: idsToDelete)
        reload()
    }

    /// Toggles the favourite flag for an album.
    /// - Parameter album: The album whose favourite state should toggle.
    func toggleFavourite(_ album: Album) {
        repository.toggleFavourite(id: album.id)
        reload()
    }

    /// Toggles the favourite flag for an album by its UUID.
    /// - Parameter id: The UUID of the album.
    func toggleFavourite(id: UUID) {
        repository.toggleFavourite(id: id)
        reload()
    }

    /// Increments the listen count for an album.
    /// - Parameter album: The album whose listen count should increase.
    func incrementListenCount(_ album: Album) {
        repository.incrementListenCount(id: album.id)
        reload()
    }

    /// Increments the listen count for an album by its UUID.
    /// - Parameter id: The UUID of the album.
    func incrementListenCount(id: UUID) {
        repository.incrementListenCount(id: id)
        reload()
    }

    /// Resets the collection to default sample albums.
    func resetToSampleData() {
        repository.resetToSampleData()
        reload()
    }
}

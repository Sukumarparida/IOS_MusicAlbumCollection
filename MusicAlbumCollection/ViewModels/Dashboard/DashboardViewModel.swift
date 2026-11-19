import SwiftUI
import Combine

/// View model computing and exposing dynamic metrics, highlights, and recent history for the Dashboard.
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var totalAlbums: Int = 0
    @Published private(set) var totalArtists: Int = 0
    @Published private(set) var favouriteCount: Int = 0
    @Published private(set) var totalTracks: Int = 0
    @Published private(set) var recentlyAdded: [Album] = []
    @Published private(set) var topListened: [Album] = []
    @Published private(set) var hasAlbums: Bool = false

    private let repository: AlbumRepository
    private let listeningService: ListeningService
    private var cancellables = Set<AnyCancellable>()

    /// Initializes DashboardViewModel with repository and listening service dependencies.
    /// - Parameter repository: Optional album repository; defaults to DefaultAlbumRepository.
    init(repository: AlbumRepository? = nil) {
        let repo = repository ?? DefaultAlbumRepository()
        self.repository = repo
        self.listeningService = ListeningService(repository: repo)
        refresh()
    }

    /// Connects to an AlbumViewModel to observe live changes reactively.
    /// - Parameter albumViewModel: The AlbumViewModel providing real-time album updates.
    func bind(to albumViewModel: AlbumViewModel) {
        cancellables.removeAll()
        albumViewModel.$albums
            .sink { [weak self] albums in
                self?.update(with: albums)
            }
            .store(in: &cancellables)
        update(with: albumViewModel.albums)
    }

    /// Recalculates metrics directly from the repository's current state.
    func refresh() {
        update(with: repository.albums)
    }

    /// Updates metrics and highlighting lists given an updated array of albums.
    /// - Parameter albums: The current full list of albums.
    func update(with albums: [Album]) {
        self.totalAlbums = albums.count
        self.totalArtists = Set(albums.map { $0.artist.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }).count
        self.favouriteCount = albums.filter { $0.isFavourite }.count
        self.totalTracks = albums.reduce(0) { $0 + $1.trackCount }
        self.recentlyAdded = Array(albums.sorted { $0.dateAdded > $1.dateAdded }.prefix(5))
        self.topListened = listeningService.topListened(from: albums, limit: 5)
        self.hasAlbums = !albums.isEmpty
    }
}

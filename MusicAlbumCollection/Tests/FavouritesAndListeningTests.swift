import Testing
import Foundation

@Suite("Favourites & Listening Module Tests")
struct FavouritesAndListeningTests {

    let testStorageURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_fav_listen_\(UUID().uuidString).json")

    // MARK: - Feature 1: Favourites Persistence & Actions

    @Test("Tapping favourite toggles state and persists changes to repository")
    @MainActor
    func favouriteToggleAndPersistence() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "fav_test_\(UUID().uuidString)")!

        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )
        let albumVM = AlbumViewModel(repository: repository)

        let testAlbum = Album(
            name: "Dark Side of the Moon",
            artist: "Pink Floyd",
            genre: .rock,
            releaseYear: 1973,
            musicDirector: "Pink Floyd",
            trackCount: 10,
            isFavourite: false
        )
        albumVM.addAlbum(testAlbum)

        // 1. Initial favourite status is false
        #expect(albumVM.album(withID: testAlbum.id)?.isFavourite == false)
        #expect(!albumVM.favouriteAlbums.contains(where: { $0.id == testAlbum.id }))

        // 2. Toggle to favourite
        albumVM.toggleFavourite(testAlbum)
        #expect(albumVM.album(withID: testAlbum.id)?.isFavourite == true)
        #expect(albumVM.favouriteAlbums.contains(where: { $0.id == testAlbum.id }))

        // 3. Verify persistence across fresh repository session
        let reloadedRepo = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )
        #expect(reloadedRepo.getAlbum(by: testAlbum.id)?.isFavourite == true)

        // 4. Remove from favourites
        albumVM.toggleFavourite(testAlbum)
        #expect(albumVM.album(withID: testAlbum.id)?.isFavourite == false)
        #expect(!albumVM.favouriteAlbums.contains(where: { $0.id == testAlbum.id }))
    }

    @Test("Dashboard favourite statistics update immediately when favourites change")
    @MainActor
    func dashboardFavouriteStatsUpdateImmediately() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "fav_stats_\(UUID().uuidString)")!

        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )
        let albumVM = AlbumViewModel(repository: repository)
        let dashVM = DashboardViewModel(repository: repository)
        dashVM.bind(to: albumVM)

        let initialFavCount = dashVM.favouriteCount

        let album = Album(
            name: "Rumours",
            artist: "Fleetwood Mac",
            genre: .rock,
            releaseYear: 1977,
            musicDirector: "Fleetwood Mac",
            trackCount: 11,
            isFavourite: false
        )
        albumVM.addAlbum(album)
        #expect(dashVM.favouriteCount == initialFavCount)

        // Mark as favourite
        albumVM.toggleFavourite(album)
        #expect(dashVM.favouriteCount == initialFavCount + 1)

        // Remove favourite
        albumVM.toggleFavourite(album)
        #expect(dashVM.favouriteCount == initialFavCount)
    }

    // MARK: - Feature 2: Listen Tracking

    @Test("Listened action increments listen count by exactly one and persists")
    @MainActor
    func listenTrackingIncrementsByExactlyOne() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "listen_test_\(UUID().uuidString)")!

        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )
        let albumVM = AlbumViewModel(repository: repository)

        let album = Album(
            name: "Bad",
            artist: "Michael Jackson",
            genre: .pop,
            releaseYear: 1987,
            musicDirector: "Quincy Jones",
            trackCount: 11,
            listenCount: 0
        )
        albumVM.addAlbum(album)

        #expect(albumVM.album(withID: album.id)?.listenCount == 0)

        // Increment once
        albumVM.incrementListenCount(album)
        #expect(albumVM.album(withID: album.id)?.listenCount == 1)

        // Increment second time
        albumVM.incrementListenCount(album)
        #expect(albumVM.album(withID: album.id)?.listenCount == 2)

        // Verify persisted state in fresh repository instance
        let reloadedRepo = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )
        #expect(reloadedRepo.getAlbum(by: album.id)?.listenCount == 2)
    }

    @Test("Dashboard Top Listened updates reactively when listen count changes")
    @MainActor
    func dashboardTopListenedReactivity() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "dash_top_\(UUID().uuidString)")!

        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )
        let albumVM = AlbumViewModel(repository: repository)
        let dashVM = DashboardViewModel(repository: repository)
        dashVM.bind(to: albumVM)

        let starAlbum = Album(
            name: "Starboy",
            artist: "The Weeknd",
            genre: .pop,
            releaseYear: 2016,
            musicDirector: "Daft Punk",
            trackCount: 18,
            listenCount: 0
        )
        albumVM.addAlbum(starAlbum)

        // Initially zero listens -> not in top picks
        #expect(!dashVM.topListened.contains(where: { $0.id == starAlbum.id }))

        // Increment listen count to 50
        for _ in 0..<50 {
            albumVM.incrementListenCount(starAlbum)
        }

        #expect(dashVM.topListened.first?.id == starAlbum.id)
        #expect(dashVM.topListened.first?.listenCount == 50)
    }

    // MARK: - Feature 3: Top Listened Requirements & Equal Counts

    @Test("ListeningService sorts by highest count and breaks ties consistently")
    @MainActor
    func listeningServiceTieBreakingAndLimits() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "svc_test_\(UUID().uuidString)")!

        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )
        let service = ListeningService(repository: repository)

        let date1 = Date().addingTimeInterval(-1000)
        let date2 = Date().addingTimeInterval(-500)
        let date3 = Date()

        let albumA = Album(name: "Album A", artist: "Artist", genre: .rock, releaseYear: 2020, musicDirector: "D", trackCount: 5, listenCount: 10, dateAdded: date1)
        let albumB = Album(name: "Album B", artist: "Artist", genre: .pop, releaseYear: 2021, musicDirector: "D", trackCount: 6, listenCount: 10, dateAdded: date2)
        let albumC = Album(name: "Album C", artist: "Artist", genre: .film, releaseYear: 2022, musicDirector: "D", trackCount: 7, listenCount: 15, dateAdded: date3)
        let albumZero = Album(name: "Zero Album", artist: "Artist", genre: .folk, releaseYear: 2023, musicDirector: "D", trackCount: 8, listenCount: 0, dateAdded: date3)

        let top = service.topListened(from: [albumA, albumB, albumC, albumZero], limit: 5)

        // 1. Zero-listen album is excluded from top picks
        #expect(!top.contains(where: { $0.id == albumZero.id }))

        // 2. Highest listen count (15) is first
        #expect(top.first?.id == albumC.id)

        // 3. For equal listen count (10 vs 10), dateAdded resolves tie (albumB added after albumA)
        #expect(top[1].id == albumB.id)
        #expect(top[2].id == albumA.id)

        // 4. Total listens
        #expect(service.totalListens(in: [albumA, albumB, albumC, albumZero]) == 35)
    }

    // MARK: - Feature 4: FavouriteViewModel & Empty State

    @Test("FavouriteViewModel filtering, search, and repository synchronization")
    @MainActor
    func favouriteViewModelOperations() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "fav_vm_\(UUID().uuidString)")!

        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )
        let albumVM = AlbumViewModel(repository: repository)
        let favVM = FavouriteViewModel(repository: repository)
        favVM.bind(to: albumVM)

        let favRock = Album(name: "Hotel California", artist: "Eagles", genre: .rock, releaseYear: 1976, musicDirector: "Bill Szymczyk", trackCount: 9, isFavourite: true)
        let favPop = Album(name: "1989", artist: "Taylor Swift", genre: .pop, releaseYear: 2014, musicDirector: "Max Martin", trackCount: 13, isFavourite: true)
        let normalAlbum = Album(name: "Normal Album", artist: "Artist", genre: .classical, releaseYear: 2000, musicDirector: "D", trackCount: 4, isFavourite: false)

        albumVM.addAlbum(favRock)
        albumVM.addAlbum(favPop)
        albumVM.addAlbum(normalAlbum)

        #expect(favVM.favouriteAlbums.contains(where: { $0.id == favRock.id }))
        #expect(favVM.favouriteAlbums.contains(where: { $0.id == favPop.id }))
        #expect(!favVM.favouriteAlbums.contains(where: { $0.id == normalAlbum.id }))

        // Search filtering
        favVM.searchText = "Taylor"
        #expect(favVM.filteredFavourites.count == 1)
        #expect(favVM.filteredFavourites.first?.name == "1989")

        // Genre filtering
        favVM.searchText = ""
        favVM.selectedGenre = .rock
        #expect(favVM.filteredFavourites.contains(where: { $0.name == "Hotel California" }))
        #expect(!favVM.filteredFavourites.contains(where: { $0.name == "1989" }))

        // Removing favourite via ViewModel
        favVM.selectedGenre = nil
        favVM.removeFavourite(id: favRock.id)
        #expect(!favVM.favouriteAlbums.contains(where: { $0.id == favRock.id }))
        #expect(albumVM.album(withID: favRock.id)?.isFavourite == false)
    }
}

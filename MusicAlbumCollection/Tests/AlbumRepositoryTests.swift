import Testing
import Foundation

// MARK: - Mock File Storage

final class MockFileStorage: FileStorageProtocol, @unchecked Sendable {
    var fileData: [URL: Data] = [:]
    var backedUpFiles: [URL] = []

    func fileExists(at url: URL) -> Bool {
        fileData[url] != nil
    }

    func load<T: Decodable>(from url: URL) throws -> T {
        guard let data = fileData[url] else {
            throw FileStorageError.fileNotFound(url)
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            _ = backupCorruptedFile(at: url)
            throw FileStorageError.decodingFailed(error.localizedDescription)
        }
    }

    func save<T: Encodable>(_ value: T, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        fileData[url] = try encoder.encode(value)
    }

    func backupCorruptedFile(at url: URL) -> URL? {
        backedUpFiles.append(url)
        let backupURL = url.appendingPathExtension("corrupted")
        fileData[backupURL] = fileData[url]
        fileData.removeValue(forKey: url)
        return backupURL
    }
}

// MARK: - Album Repository Unit Tests

@Suite("Album Persistence & Repository Tests")
struct AlbumRepositoryTests {

    let testStorageURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test_albums_\(UUID().uuidString).json")

    @Test("First launch with missing file creates sample data and writes atomically")
    @MainActor
    func firstLaunchMissingFile() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "test_suite_\(UUID().uuidString)")!

        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )

        #expect(!repository.albums.isEmpty)
        #expect(repository.albums.count == 5)
        #expect(mockStorage.fileExists(at: testStorageURL))
    }

    @Test("Application restart reloads saved albums and never re-inserts duplicate sample data")
    @MainActor
    func applicationRestartPersistence() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "test_suite_\(UUID().uuidString)")!

        // Session 1: Launch and add a custom album
        let session1 = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )
        let customAlbum = Album(
            name: "Discovery",
            artist: "Daft Punk",
            genre: .pop,
            releaseYear: 2001,
            musicDirector: "Daft Punk",
            trackCount: 14,
            favouriteTrack: "One More Time",
            artworkIdentifier: "discovery_art"
        )
        session1.addAlbum(customAlbum)
        let countAfterAdd = session1.albums.count

        // Session 2: Simulate application restart using the same storage URL
        let session2 = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )

        #expect(session2.albums.count == countAfterAdd)
        #expect(session2.albums.contains(where: { $0.name == "Discovery" && $0.artist == "Daft Punk" }))
        // Verify artworkIdentifier was persisted and restored
        #expect(session2.getAlbum(by: customAlbum.id)?.artworkIdentifier == "discovery_art")
    }

    @Test("Migration from legacy UserDefaults imports data and deletes legacy key")
    @MainActor
    func migrationFromUserDefaults() throws {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "migration_test_\(UUID().uuidString)")!
        let legacyKey = "savedAlbums"

        // Seed UserDefaults with legacy album data
        let legacyAlbum = Album(
            name: "Kind of Blue",
            artist: "Miles Davis",
            genre: .other,
            releaseYear: 1959,
            musicDirector: "Miles Davis",
            trackCount: 5
        )
        let legacyData = try JSONEncoder().encode([legacyAlbum])
        defaults.set(legacyData, forKey: legacyKey)

        // Launch repository where file does not exist yet
        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults,
            userDefaultsKey: legacyKey
        )

        // Verify data was migrated into the repository
        #expect(repository.albums.count == 1)
        #expect(repository.albums.first?.name == "Kind of Blue")

        // Verify it was saved to the file
        #expect(mockStorage.fileExists(at: testStorageURL))

        // Verify legacy key was cleaned up
        #expect(defaults.data(forKey: legacyKey) == nil)
    }

    @Test("Corrupted JSON file is handled gracefully without crashing")
    @MainActor
    func corruptedJSONHandling() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "corrupt_test_\(UUID().uuidString)")!

        // Seed file with corrupt non-JSON data
        mockStorage.fileData[testStorageURL] = "INVALID_CORRUPT_JSON_DATA".data(using: .utf8)

        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )

        // Should not crash, and should load valid sample data
        #expect(!repository.albums.isEmpty)
        #expect(mockStorage.backedUpFiles.contains(testStorageURL))
    }

    @Test("Data rule: Listen count can never become negative")
    @MainActor
    func listenCountNeverNegative() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "rules_test_\(UUID().uuidString)")!

        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )

        let albumWithNegativeListens = Album(
            name: "Negative Test",
            artist: "Artist",
            genre: .rock,
            releaseYear: 2020,
            musicDirector: "Director",
            trackCount: 8,
            listenCount: -10
        )
        repository.addAlbum(albumWithNegativeListens)

        let stored = repository.getAlbum(by: albumWithNegativeListens.id)
        #expect(stored?.listenCount == 0)
    }

    @Test("Data rule: Track count must be greater than zero")
    @MainActor
    func trackCountGreaterThanZero() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "rules_test_\(UUID().uuidString)")!

        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )

        let invalidTrackAlbum = Album(
            name: "Zero Tracks",
            artist: "Artist",
            genre: .rock,
            releaseYear: 2020,
            musicDirector: "Director",
            trackCount: 0
        )
        repository.addAlbum(invalidTrackAlbum)

        let stored = repository.getAlbum(by: invalidTrackAlbum.id)
        #expect(stored?.trackCount == 1)
    }

    @Test("Data rule: Empty album name or artist name is rejected")
    @MainActor
    func emptyNameOrArtistRejected() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "rules_test_\(UUID().uuidString)")!

        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )
        let initialCount = repository.albums.count

        let emptyNameAlbum = Album(
            name: "   ",
            artist: "Valid Artist",
            genre: .rock,
            releaseYear: 2020,
            musicDirector: "Director",
            trackCount: 5
        )
        repository.addAlbum(emptyNameAlbum)
        #expect(repository.albums.count == initialCount)

        let emptyArtistAlbum = Album(
            name: "Valid Name",
            artist: "   ",
            genre: .rock,
            releaseYear: 2020,
            musicDirector: "Director",
            trackCount: 5
        )
        repository.addAlbum(emptyArtistAlbum)
        #expect(repository.albums.count == initialCount)
    }

    @Test("ViewModel reflects changes immediately across computed properties")
    @MainActor
    func viewModelImmediateStateUpdate() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "vm_test_\(UUID().uuidString)")!

        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )
        let viewModel = AlbumViewModel(repository: repository)

        let originalTotal = viewModel.totalAlbums
        let testAlbum = Album(
            name: "Rumours",
            artist: "Fleetwood Mac",
            genre: .rock,
            releaseYear: 1977,
            musicDirector: "Fleetwood Mac",
            trackCount: 11,
            isFavourite: true
        )

        viewModel.addAlbum(testAlbum)

        #expect(viewModel.totalAlbums == originalTotal + 1)
        #expect(viewModel.favouriteAlbums.contains(where: { $0.name == "Rumours" }))
        #expect(viewModel.recentlyAdded.first?.name == "Rumours")

        // Increment listen count
        viewModel.incrementListenCount(testAlbum)
        #expect(viewModel.album(withID: testAlbum.id)?.listenCount == 1)
        #expect(viewModel.topListened.contains(where: { $0.id == testAlbum.id }))

        // Toggle favourite
        viewModel.toggleFavourite(testAlbum)
        #expect(viewModel.album(withID: testAlbum.id)?.isFavourite == false)

        // Delete album
        viewModel.deleteAlbum(testAlbum)
        #expect(viewModel.totalAlbums == originalTotal)
        #expect(viewModel.album(withID: testAlbum.id) == nil)
    }

    @Test("DashboardViewModel dynamic statistics, reactivity, and sorting")
    @MainActor
    func dashboardDynamicStatisticsAndReactivity() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "dash_suite_\(UUID().uuidString)")!

        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )
        let albumVM = AlbumViewModel(repository: repository)
        let dashVM = DashboardViewModel(repository: repository)
        dashVM.bind(to: albumVM)

        // Initial stats check (5 sample albums)
        #expect(dashVM.totalAlbums == 5)
        #expect(dashVM.totalTracks == (6 + 17 + 9 + 12 + 4))
        #expect(dashVM.recentlyAdded.count == 5)
        #expect(dashVM.hasAlbums == true)

        // Adding an album updates stats and Recently Added immediately
        let newAlbum = Album(
            name: "Random Access Memories",
            artist: "Daft Punk",
            genre: .pop,
            releaseYear: 2013,
            musicDirector: "Daft Punk",
            trackCount: 13,
            favouriteTrack: "Get Lucky",
            listenCount: 0,
            isFavourite: true,
            dateAdded: Date()
        )
        albumVM.addAlbum(newAlbum)

        #expect(dashVM.totalAlbums == 6)
        #expect(dashVM.totalTracks == 48 + 13)
        #expect(dashVM.favouriteCount == 1)
        #expect(dashVM.recentlyAdded.first?.id == newAlbum.id)

        // Incrementing listen count updates Top Listened in descending order
        albumVM.incrementListenCount(newAlbum)
        albumVM.incrementListenCount(newAlbum)
        #expect(dashVM.topListened.first?.id == newAlbum.id)
        #expect(dashVM.topListened.first?.listenCount == 2)

        // Toggle favourite updates immediately
        albumVM.toggleFavourite(newAlbum)
        #expect(dashVM.favouriteCount == 0)

        // Deleting album updates stats, Recently Added, and Top Listened immediately
        albumVM.deleteAlbum(newAlbum)
        #expect(dashVM.totalAlbums == 5)
        #expect(!dashVM.recentlyAdded.contains(where: { $0.id == newAlbum.id }))
        #expect(!dashVM.topListened.contains(where: { $0.id == newAlbum.id }))
    }

    @Test("DashboardViewModel empty collection handling")
    @MainActor
    func dashboardEmptyCollectionHandling() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "dash_empty_\(UUID().uuidString)")!
        let emptyURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("empty_\(UUID().uuidString).json")

        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: emptyURL,
            userDefaults: defaults
        )
        repository.deleteAlbums(ids: repository.albums.map { $0.id })

        let albumVM = AlbumViewModel(repository: repository)
        let dashVM = DashboardViewModel(repository: repository)
        dashVM.bind(to: albumVM)

        #expect(dashVM.totalAlbums == 0)
        #expect(dashVM.totalArtists == 0)
        #expect(dashVM.totalTracks == 0)
        #expect(dashVM.favouriteCount == 0)
        #expect(dashVM.hasAlbums == false)
        #expect(dashVM.recentlyAdded.isEmpty)
        #expect(dashVM.topListened.isEmpty)
    }

    // MARK: - Album Form Validator & View Models Tests

    @Test("AlbumFormValidator validates album name and artist correctly")
    func formValidatorNameAndArtist() {
        #expect(AlbumFormValidator.validateName("") != nil)
        #expect(AlbumFormValidator.validateName("   ") != nil)
        #expect(AlbumFormValidator.validateName("Valid Name") == nil)

        #expect(AlbumFormValidator.validateArtist("") != nil)
        #expect(AlbumFormValidator.validateArtist("   ") != nil)
        #expect(AlbumFormValidator.validateArtist("Valid Artist") == nil)
    }

    @Test("AlbumFormValidator validates release year range (1900 to current year)")
    func formValidatorReleaseYear() {
        let currentYear = Calendar.current.component(.year, from: Date())

        #expect(AlbumFormValidator.validateReleaseYear("") != nil)
        #expect(AlbumFormValidator.validateReleaseYear("abc") != nil)
        #expect(AlbumFormValidator.validateReleaseYear("1899") != nil)
        #expect(AlbumFormValidator.validateReleaseYear("\(currentYear + 1)") != nil)

        #expect(AlbumFormValidator.validateReleaseYear("1900") == nil)
        #expect(AlbumFormValidator.validateReleaseYear("1995") == nil)
        #expect(AlbumFormValidator.validateReleaseYear("\(currentYear)") == nil)
    }

    @Test("AlbumFormValidator validates track count (> 0)")
    func formValidatorTrackCount() {
        #expect(AlbumFormValidator.validateTrackCount("") != nil)
        #expect(AlbumFormValidator.validateTrackCount("0") != nil)
        #expect(AlbumFormValidator.validateTrackCount("-5") != nil)
        #expect(AlbumFormValidator.validateTrackCount("xyz") != nil)

        #expect(AlbumFormValidator.validateTrackCount("1") == nil)
        #expect(AlbumFormValidator.validateTrackCount("12") == nil)
    }

    @Test("AlbumFormViewModel preserves ID, dateAdded, listenCount, and isFavourite when editing")
    @MainActor
    func formViewModelPreservesMetadata() {
        let originalDate = Date(timeIntervalSince1970: 1_000_000)
        let originalID = UUID()
        let existingAlbum = Album(
            id: originalID,
            name: "Original Name",
            artist: "Original Artist",
            genre: .rock,
            releaseYear: 1990,
            musicDirector: "Old Director",
            trackCount: 10,
            favouriteTrack: "Old Track",
            listenCount: 42,
            isFavourite: true,
            notes: "Old Notes",
            dateAdded: originalDate,
            artworkIdentifier: "vinyl_classic"
        )

        let formVM = AlbumFormViewModel(albumToEdit: existingAlbum)
        #expect(formVM.isEditing)
        #expect(formVM.isValid)

        // Modify editable fields
        formVM.name = "Updated Name"
        formVM.artist = "Updated Artist"
        formVM.releaseYear = "1995"
        formVM.trackCount = "12"
        formVM.musicDirector = "New Director"
        formVM.favouriteTrack = "New Track"
        formVM.notes = "New Notes"

        let updated = formVM.buildAlbum()
        #expect(updated != nil)
        #expect(updated?.id == originalID)
        #expect(updated?.dateAdded == originalDate)
        #expect(updated?.listenCount == 42)
        #expect(updated?.isFavourite == true)
        #expect(updated?.name == "Updated Name")
        #expect(updated?.artist == "Updated Artist")
        #expect(updated?.releaseYear == 1995)
        #expect(updated?.trackCount == 12)
    }

    @Test("AlbumDetailViewModel presents formatted data and handles actions")
    @MainActor
    func detailViewModelPresentationAndActions() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "detail_vm_\(UUID().uuidString)")!
        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )
        let albumVM = AlbumViewModel(repository: repository)

        let album = repository.albums.first!
        let detailVM = AlbumDetailViewModel(albumID: album.id, repository: repository)
        detailVM.bind(to: albumVM)

        #expect(detailVM.name == album.name)
        #expect(detailVM.artist == album.artist)
        #expect(detailVM.genreName == album.genre.rawValue)
        #expect(!detailVM.formattedDateAdded.isEmpty)
        #expect(detailVM.listenCount == album.listenCount)

        // Test toggle favourite
        let prevFav = detailVM.isFavourite
        detailVM.toggleFavourite()
        #expect(detailVM.isFavourite == !prevFav)

        // Test listen count increment
        let prevListens = detailVM.listenCount
        detailVM.recordListen()
        #expect(detailVM.listenCount == prevListens + 1)

        // Test delete album
        let deleted = detailVM.deleteAlbum()
        #expect(deleted == true)
        #expect(detailVM.album == nil)
        #expect(albumVM.album(withID: album.id) == nil)
    }

    // MARK: - Search, Genre Filter & Sorting Tests

    @Test("AlbumSortOption sorts collections correctly across all 8 variants without mutating source")
    func sortOptionAllVariants() {
        let baseDate = Date(timeIntervalSince1970: 10_000_000)
        let albums = [
            Album(name: "Charlie", artist: "Zeta", genre: .rock, releaseYear: 2010, musicDirector: "", trackCount: 8, listenCount: 5, dateAdded: baseDate.addingTimeInterval(100)),
            Album(name: "Alpha", artist: "Beta", genre: .pop, releaseYear: 2020, musicDirector: "", trackCount: 10, listenCount: 20, dateAdded: baseDate.addingTimeInterval(300)),
            Album(name: "Bravo", artist: "Alpha", genre: .film, releaseYear: 1995, musicDirector: "", trackCount: 6, listenCount: 15, dateAdded: baseDate.addingTimeInterval(200))
        ]

        // 1. Recently Added
        let recent = AlbumSortOption.recentlyAdded.sort(albums: albums)
        #expect(recent.map(\.name) == ["Alpha", "Bravo", "Charlie"])

        // 2. Oldest Added
        let oldest = AlbumSortOption.oldestAdded.sort(albums: albums)
        #expect(oldest.map(\.name) == ["Charlie", "Bravo", "Alpha"])

        // 3. Album Name A-Z
        let nameAZ = AlbumSortOption.albumNameAZ.sort(albums: albums)
        #expect(nameAZ.map(\.name) == ["Alpha", "Bravo", "Charlie"])

        // 4. Album Name Z-A
        let nameZA = AlbumSortOption.albumNameZA.sort(albums: albums)
        #expect(nameZA.map(\.name) == ["Charlie", "Bravo", "Alpha"])

        // 5. Artist Name
        let artistSorted = AlbumSortOption.artistName.sort(albums: albums)
        #expect(artistSorted.map(\.artist) == ["Alpha", "Beta", "Zeta"])

        // 6. Release Year Newest First
        let yearNewest = AlbumSortOption.releaseYearNewest.sort(albums: albums)
        #expect(yearNewest.map(\.name) == ["Alpha", "Charlie", "Bravo"])

        // 7. Release Year Oldest First
        let yearOldest = AlbumSortOption.releaseYearOldest.sort(albums: albums)
        #expect(yearOldest.map(\.name) == ["Bravo", "Charlie", "Alpha"])

        // 8. Most Listened
        let mostListened = AlbumSortOption.mostListened.sort(albums: albums)
        #expect(mostListened.map(\.name) == ["Alpha", "Bravo", "Charlie"])

        // Source must remain completely unchanged
        #expect(albums.map(\.name) == ["Charlie", "Alpha", "Bravo"])
    }

    @Test("AlbumFilterState applies real-time case-insensitive search and genre filter together")
    func filterStateSearchAndGenre() {
        let albums = [
            Album(name: "Roja", artist: "A. R. Rahman", genre: .film, releaseYear: 1992, musicDirector: "A. R. Rahman", trackCount: 6),
            Album(name: "Rockstar", artist: "A. R. Rahman", genre: .rock, releaseYear: 2011, musicDirector: "A. R. Rahman", trackCount: 14),
            Album(name: "Abbey Road", artist: "The Beatles", genre: .rock, releaseYear: 1969, musicDirector: "George Martin", trackCount: 17)
        ]

        var state = AlbumFilterState()

        // Empty filter returns all
        #expect(state.apply(to: albums).count == 3)
        #expect(!state.isFilteringActive)

        // Case-insensitive partial name search
        state.searchText = "roj"
        #expect(state.apply(to: albums).map(\.name) == ["Roja"])

        // Case-insensitive artist search
        state.searchText = "rahman"
        #expect(state.apply(to: albums).count == 2)

        // Combined search + genre filter
        state.selectedGenre = .rock
        let combined = state.apply(to: albums)
        #expect(combined.count == 1)
        #expect(combined.first?.name == "Rockstar")

        // Clearing search retains genre
        state.searchText = ""
        let genreOnly = state.apply(to: albums)
        #expect(genreOnly.count == 2)
        #expect(genreOnly.allSatisfy { $0.genre == .rock })

        // Reset restores all
        state.reset()
        #expect(state.apply(to: albums).count == 3)
    }

    @Test("AlbumListViewModel manages search, genre, sort state and empty indicators")
    @MainActor
    func listViewModelSearchFilterSorting() {
        let mockStorage = MockFileStorage()
        let defaults = UserDefaults(suiteName: "list_vm_\(UUID().uuidString)")!
        let repository = DefaultAlbumRepository(
            fileStorage: mockStorage,
            storageURL: testStorageURL,
            userDefaults: defaults
        )
        let albumVM = AlbumViewModel(repository: repository)
        let listVM = AlbumListViewModel(repository: repository, favouritesOnly: false)
        listVM.bind(to: albumVM)

        #expect(listVM.displayedAlbums.count == 5)
        #expect(listVM.activeFilterCount == 0)

        // Search
        listVM.searchText = "rahman"
        #expect(listVM.isSearchingOrFiltering)
        #expect(listVM.displayedAlbums.allSatisfy { $0.artist.localizedCaseInsensitiveContains("rahman") })

        // Genre
        listVM.selectedGenre = .rock
        #expect(listVM.activeFilterCount == 1)

        // Sort option
        listVM.sortOption = .albumNameAZ
        #expect(listVM.activeFilterCount == 2)

        // Empty search result handling
        listVM.searchText = "NON_EXISTENT_QUERY_123"
        #expect(listVM.isEmpty)
        #expect(listVM.emptyTitle == "No Results Found")
        #expect(listVM.emptyIcon == "magnifyingglass")

        // Clear search restores
        listVM.clearSearch()
        #expect(listVM.searchText.isEmpty)

        // Reset all
        listVM.resetAll()
        #expect(listVM.activeFilterCount == 0)
        #expect(listVM.displayedAlbums.count == 5)
    }

    @Test("FavouriteViewModel respects active search and genre filter")
    @MainActor
    func favouriteViewModelSearchAndFilter() {
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

        // Mark two albums as favourites with different genres
        let album1 = repository.albums[0]
        let album2 = repository.albums[1]
        albumVM.toggleFavourite(album1)
        albumVM.toggleFavourite(album2)

        #expect(favVM.totalFavourites == 2)

        // Search within favourites
        favVM.searchText = album1.name
        #expect(favVM.filteredFavourites.count == 1)
        #expect(favVM.filteredFavourites.first?.id == album1.id)

        // Filter by matching genre
        favVM.searchText = ""
        favVM.selectedGenre = album2.genre
        #expect(favVM.filteredFavourites.allSatisfy { $0.genre == album2.genre })

        // Reset
        favVM.searchText = ""
        favVM.selectedGenre = nil
        #expect(favVM.filteredFavourites.count == 2)
    }
}

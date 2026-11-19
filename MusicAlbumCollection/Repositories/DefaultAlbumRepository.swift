import Foundation

/// Persistent local album repository storing data in Application Support with atomic writes and legacy UserDefaults migration.
@MainActor
final class DefaultAlbumRepository: AlbumRepository {
    private let fileStorage: FileStorageProtocol
    private let fileURL: URL
    private let userDefaults: UserDefaults
    private let userDefaultsKey: String

    private(set) var albums: [Album] = []

    /// Default file location in the Application Support directory: Application Support/MusicAlbumCollection/albums.json
    static func defaultStorageURL() -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let collectionDir = appSupport.appendingPathComponent("MusicAlbumCollection", isDirectory: true)
        return collectionDir.appendingPathComponent("albums.json")
    }

    init(
        fileStorage: FileStorageProtocol? = nil,
        storageURL: URL? = nil,
        userDefaults: UserDefaults = .standard,
        userDefaultsKey: String? = nil
    ) {
        self.fileStorage = fileStorage ?? FileStorageService()
        self.fileURL = storageURL ?? Self.defaultStorageURL()
        self.userDefaults = userDefaults
        self.userDefaultsKey = userDefaultsKey ?? AppConstants.Storage.savedAlbumsKey
        loadDataWithMigration()
    }

    // MARK: - Loading & Migration

    /// Loads saved collection, gracefully handles corruption, and migrates from UserDefaults if needed.
    private func loadDataWithMigration() {
        if fileStorage.fileExists(at: fileURL) {
            do {
                let savedAlbums: [Album] = try fileStorage.load(from: fileURL)
                self.albums = savedAlbums
                return
            } catch {
                // File exists but was corrupted. fileStorage has backed it up.
                // Attempt recovery from legacy UserDefaults backup if present
                if let legacyData = userDefaults.data(forKey: userDefaultsKey),
                   let recoveredAlbums = try? JSONDecoder().decode([Album].self, from: legacyData),
                   !recoveredAlbums.isEmpty {
                    self.albums = recoveredAlbums
                    persist()
                    return
                }

                // Fallback to sample data to prevent crash
                let fallbackSample = SampleDataService.makeSampleAlbums()
                self.albums = fallbackSample
                persist()
                return
            }
        }

        // File does not exist yet. Check if legacy data exists in UserDefaults
        if let legacyData = userDefaults.data(forKey: userDefaultsKey),
           let legacyAlbums = try? JSONDecoder().decode([Album].self, from: legacyData),
           !legacyAlbums.isEmpty {
            self.albums = legacyAlbums
            persist()
            // Remove legacy key after successful migration to prevent redundant overwriting
            userDefaults.removeObject(forKey: userDefaultsKey)
            return
        }

        // Very first launch: seed with sample albums
        let initialSample = SampleDataService.makeSampleAlbums()
        self.albums = initialSample
        persist()
    }

    /// Persists current album state atomically to the Application Support file.
    private func persist() {
        do {
            try fileStorage.save(albums, to: fileURL)
        } catch {
            #if DEBUG
            print("Failed to persist albums to \(fileURL.path): \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - AlbumRepository Protocol Methods

    func fetchAlbums() -> [Album] {
        return albums
    }

    func getAlbum(by id: UUID) -> Album? {
        albums.first { $0.id == id }
    }

    func addAlbum(_ album: Album) {
        let cleanName = album.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanArtist = album.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, !cleanArtist.isEmpty else { return }

        var validatedAlbum = album
        validatedAlbum.name = cleanName
        validatedAlbum.artist = cleanArtist
        validatedAlbum.trackCount = max(1, album.trackCount)
        validatedAlbum.listenCount = max(0, album.listenCount)

        // Ensure unique ID rule
        if albums.contains(where: { $0.id == validatedAlbum.id }) {
            validatedAlbum.id = UUID()
        }

        let currentYear = Calendar.current.component(.year, from: Date())
        if validatedAlbum.releaseYear < AppConstants.Validation.minimumYear || validatedAlbum.releaseYear > currentYear {
            validatedAlbum.releaseYear = currentYear
        }

        albums.append(validatedAlbum)
        persist()
    }

    func updateAlbum(_ album: Album) {
        let cleanName = album.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanArtist = album.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, !cleanArtist.isEmpty else { return }

        guard let index = albums.firstIndex(where: { $0.id == album.id }) else { return }

        var validatedAlbum = album
        validatedAlbum.name = cleanName
        validatedAlbum.artist = cleanArtist
        validatedAlbum.trackCount = max(1, album.trackCount)
        validatedAlbum.listenCount = max(0, album.listenCount)

        let currentYear = Calendar.current.component(.year, from: Date())
        if validatedAlbum.releaseYear < AppConstants.Validation.minimumYear || validatedAlbum.releaseYear > currentYear {
            validatedAlbum.releaseYear = currentYear
        }

        albums[index] = validatedAlbum
        persist()
    }

    func deleteAlbum(id: UUID) {
        albums.removeAll { $0.id == id }
        persist()
    }

    func deleteAlbums(ids: [UUID]) {
        albums.removeAll { ids.contains($0.id) }
        persist()
    }

    func toggleFavourite(id: UUID) {
        guard let index = albums.firstIndex(where: { $0.id == id }) else { return }
        albums[index].isFavourite.toggle()
        persist()
    }

    func incrementListenCount(id: UUID) {
        guard let index = albums.firstIndex(where: { $0.id == id }) else { return }
        albums[index].listenCount = max(0, albums[index].listenCount + 1)
        persist()
    }

    func resetToSampleData() {
        let sample = SampleDataService.makeSampleAlbums()
        self.albums = sample
        persist()
    }
}

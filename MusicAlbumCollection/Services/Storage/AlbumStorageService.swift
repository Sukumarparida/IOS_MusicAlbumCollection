import Foundation

/// Saves and loads the album collection using StorageServiceProtocol.
struct AlbumStorageService {
    private let storage: StorageServiceProtocol
    private let key: String

    init(storage: StorageServiceProtocol = UserDefaultsStorageService(), key: String = AppConstants.Storage.savedAlbumsKey) {
        self.storage = storage
        self.key = key
    }

    /// Returns saved albums, or nil if nothing has been saved yet.
    func load() -> [Album]? {
        storage.load(forKey: key)
    }

    /// Writes the full album list to storage.
    func save(_ albums: [Album]) {
        storage.save(albums, forKey: key)
    }
}

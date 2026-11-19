import Foundation

/// Validation errors that can be thrown when modifying album data.
enum AlbumValidationError: LocalizedError, Equatable {
    case emptyName
    case emptyArtist
    case invalidYear(Int)
    case invalidTrackCount(Int)
    case duplicateID(UUID)

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Album name cannot be empty."
        case .emptyArtist:
            return "Artist name cannot be empty."
        case .invalidYear(let year):
            return "Release year \(year) is invalid. Must be between 1900 and current year."
        case .invalidTrackCount(let count):
            return "Track count must be greater than zero (received \(count))."
        case .duplicateID(let id):
            return "An album with ID \(id) already exists."
        }
    }
}

/// Repository protocol defining data access, querying, and persistent operations for albums.
@MainActor
protocol AlbumRepository: AnyObject {
    var albums: [Album] { get }
    func fetchAlbums() -> [Album]
    func getAlbum(by id: UUID) -> Album?
    func addAlbum(_ album: Album)
    func updateAlbum(_ album: Album)
    func deleteAlbum(id: UUID)
    func deleteAlbums(ids: [UUID])
    func toggleFavourite(id: UUID)
    func incrementListenCount(id: UUID)
    func resetToSampleData()
}

import Foundation

/// Protocol defining operations for tracking album listens and computing listening metrics.
@MainActor
protocol ListeningServiceProtocol: AnyObject {
    /// Increments the listen count of an album by exactly one in the repository.
    /// - Parameter albumID: The unique identifier of the album listened to.
    /// - Returns: The updated album if found, or nil.
    func recordListen(for albumID: UUID) -> Album?

    /// Returns the top listened albums sorted in descending order with deterministic tie-breaking.
    /// - Parameters:
    ///   - albums: The source array of albums to evaluate.
    ///   - limit: Maximum number of albums to return.
    /// - Returns: Sorted array of top played albums.
    func topListened(from albums: [Album], limit: Int) -> [Album]

    /// Returns the total listen count across all given albums.
    /// - Parameter albums: The albums whose listen counts will be aggregated.
    /// - Returns: Total number of recorded listens.
    func totalListens(in albums: [Album]) -> Int
}

/// Service managing listen recording, persistence via the central repository, and listen statistics.
@MainActor
final class ListeningService: ListeningServiceProtocol {
    private let repository: AlbumRepository

    /// Initializes the service with a central album repository.
    /// - Parameter repository: The central album repository to update.
    init(repository: AlbumRepository) {
        self.repository = repository
    }

    /// Increments the listen count of an album by exactly one and persists the change.
    /// - Parameter albumID: The unique identifier of the album listened to.
    /// - Returns: The updated album if found, or nil.
    @discardableResult
    func recordListen(for albumID: UUID) -> Album? {
        repository.incrementListenCount(id: albumID)
        return repository.getAlbum(by: albumID)
    }

    /// Returns up to `limit` most listened albums with at least one listen, sorted descending.
    /// Handles equal listen counts consistently by sorting next by date added, then alphabetically by album name.
    /// Albums with zero listens are excluded from the top picks.
    /// - Parameters:
    ///   - albums: The source array of albums to evaluate.
    ///   - limit: Maximum number of albums to return (defaults to 5).
    /// - Returns: Sorted array of top played albums.
    func topListened(from albums: [Album], limit: Int = 5) -> [Album] {
        let played = albums.filter { $0.listenCount > 0 }
        let sorted = played.sorted { first, second in
            if first.listenCount != second.listenCount {
                return first.listenCount > second.listenCount
            }
            if first.dateAdded != second.dateAdded {
                return first.dateAdded > second.dateAdded
            }
            return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
        }
        return Array(sorted.prefix(max(0, limit)))
    }

    /// Computes the total number of listens across all provided albums.
    /// - Parameter albums: The albums whose listen counts will be aggregated.
    /// - Returns: Total number of recorded listens.
    func totalListens(in albums: [Album]) -> Int {
        albums.reduce(0) { $0 + max(0, $1.listenCount) }
    }
}

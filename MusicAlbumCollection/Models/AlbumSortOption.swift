import Foundation

/// Defines all available sorting options for album collections.
enum AlbumSortOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case recentlyAdded = "Recently Added"
    case oldestAdded = "Oldest Added"
    case albumNameAZ = "Album Name A-Z"
    case albumNameZA = "Album Name Z-A"
    case artistName = "Artist Name"
    case releaseYearNewest = "Release Year: Newest First"
    case releaseYearOldest = "Release Year: Oldest First"
    case mostListened = "Most Listened"

    /// Conformance to Identifiable using raw string representation.
    var id: String { rawValue }

    /// SF Symbol icon associated with this sort option.
    var systemImage: String {
        switch self {
        case .recentlyAdded:
            return "clock.arrow.circlepath"
        case .oldestAdded:
            return "clock"
        case .albumNameAZ:
            return "textformat.abc"
        case .albumNameZA:
            return "textformat.size"
        case .artistName:
            return "person.crop.circle"
        case .releaseYearNewest:
            return "calendar.badge.clock"
        case .releaseYearOldest:
            return "calendar"
        case .mostListened:
            return "headphones"
        }
    }

    /// Sorts an array of albums according to this sort option without modifying the original collection.
    /// - Parameter albums: The source album array.
    /// - Returns: A newly sorted array of albums.
    func sort(albums: [Album]) -> [Album] {
        albums.sorted { first, second in
            switch self {
            case .recentlyAdded:
                return first.dateAdded > second.dateAdded
            case .oldestAdded:
                return first.dateAdded < second.dateAdded
            case .albumNameAZ:
                let result = first.name.localizedCaseInsensitiveCompare(second.name)
                if result == .orderedSame {
                    return first.artist.localizedCaseInsensitiveCompare(second.artist) == .orderedAscending
                }
                return result == .orderedAscending
            case .albumNameZA:
                let result = first.name.localizedCaseInsensitiveCompare(second.name)
                if result == .orderedSame {
                    return first.artist.localizedCaseInsensitiveCompare(second.artist) == .orderedAscending
                }
                return result == .orderedDescending
            case .artistName:
                let result = first.artist.localizedCaseInsensitiveCompare(second.artist)
                if result == .orderedSame {
                    return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
                }
                return result == .orderedAscending
            case .releaseYearNewest:
                if first.releaseYear == second.releaseYear {
                    return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
                }
                return first.releaseYear > second.releaseYear
            case .releaseYearOldest:
                if first.releaseYear == second.releaseYear {
                    return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
                }
                return first.releaseYear < second.releaseYear
            case .mostListened:
                if first.listenCount == second.listenCount {
                    return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
                }
                return first.listenCount > second.listenCount
            }
        }
    }
}

import Foundation

/// Encapsulates the complete filtering, search, and sorting state for the album collection.
struct AlbumFilterState: Equatable, Sendable {
    /// Search query string matching album name or artist.
    var searchText: String = ""

    /// Selected genre filter; nil represents "All Genres".
    var selectedGenre: Genre? = nil

    /// Active sorting option applied to displayed albums.
    var sortOption: AlbumSortOption = .recentlyAdded

    /// Whether any non-default search, genre filter, or sort option is active.
    var isFilteringActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedGenre != nil
            || sortOption != .recentlyAdded
    }

    /// Count of active filter attributes (genre and non-default sort).
    var activeFilterCount: Int {
        var count = 0
        if selectedGenre != nil { count += 1 }
        if sortOption != .recentlyAdded { count += 1 }
        return count
    }

    /// Resets all filter and sort settings back to default.
    mutating func reset() {
        searchText = ""
        selectedGenre = nil
        sortOption = .recentlyAdded
    }

    /// Resets only the genre and sort filters, retaining the current search text.
    mutating func resetFiltersOnly() {
        selectedGenre = nil
        sortOption = .recentlyAdded
    }

    /// Applies search, genre filtering, and sorting to an album array without modifying the source.
    /// - Parameter albums: The source array of albums.
    /// - Returns: A filtered and sorted array of albums.
    func apply(to albums: [Album]) -> [Album] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let filtered = albums.filter { album in
            let matchesSearch = query.isEmpty
                || album.name.localizedCaseInsensitiveContains(query)
                || album.artist.localizedCaseInsensitiveContains(query)

            let matchesGenre = selectedGenre == nil || album.genre == selectedGenre
            return matchesSearch && matchesGenre
        }

        return sortOption.sort(albums: filtered)
    }
}

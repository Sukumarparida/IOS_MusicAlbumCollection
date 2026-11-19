import Foundation

/// Music genres used to tag and filter albums.
enum Genre: String, CaseIterable, Codable, Identifiable, Sendable {
    case classical = "Classical"
    case film = "Film"
    case rock = "Rock"
    case pop = "Pop"
    case folk = "Folk"
    case devotional = "Devotional"
    case other = "Other"

    /// Identifiable conformance so SwiftUI can list genres in pickers.
    var id: String { rawValue }
}

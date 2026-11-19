import Foundation

/// A single album in the user's music collection.
struct Album: Identifiable, Codable, Equatable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String
    var artist: String
    var genre: Genre
    var releaseYear: Int
    var musicDirector: String
    var trackCount: Int
    var favouriteTrack: String = ""
    var listenCount: Int = 0
    var isFavourite: Bool = false
    var notes: String = ""
    var dateAdded: Date = Date()
    var artworkIdentifier: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case artist
        case genre
        case releaseYear
        case musicDirector
        case trackCount
        case favouriteTrack
        case listenCount
        case isFavourite
        case notes
        case dateAdded
        case artworkIdentifier
    }

    init(
        id: UUID = UUID(),
        name: String,
        artist: String,
        genre: Genre,
        releaseYear: Int,
        musicDirector: String,
        trackCount: Int,
        favouriteTrack: String = "",
        listenCount: Int = 0,
        isFavourite: Bool = false,
        notes: String = "",
        dateAdded: Date = Date(),
        artworkIdentifier: String? = nil
    ) {
        self.id = id
        self.name = name
        self.artist = artist
        self.genre = genre
        self.releaseYear = releaseYear
        self.musicDirector = musicDirector
        self.trackCount = max(1, trackCount)
        self.favouriteTrack = favouriteTrack
        self.listenCount = max(0, listenCount)
        self.isFavourite = isFavourite
        self.notes = notes
        self.dateAdded = dateAdded
        self.artworkIdentifier = artworkIdentifier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.artist = try container.decode(String.self, forKey: .artist)
        self.genre = try container.decodeIfPresent(Genre.self, forKey: .genre) ?? .other
        self.releaseYear = try container.decode(Int.self, forKey: .releaseYear)
        self.musicDirector = try container.decodeIfPresent(String.self, forKey: .musicDirector) ?? ""
        let decodedTrackCount = try container.decodeIfPresent(Int.self, forKey: .trackCount) ?? 1
        self.trackCount = max(1, decodedTrackCount)
        self.favouriteTrack = try container.decodeIfPresent(String.self, forKey: .favouriteTrack) ?? ""
        let decodedListenCount = try container.decodeIfPresent(Int.self, forKey: .listenCount) ?? 0
        self.listenCount = max(0, decodedListenCount)
        self.isFavourite = try container.decodeIfPresent(Bool.self, forKey: .isFavourite) ?? false
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded) ?? Date()
        self.artworkIdentifier = try container.decodeIfPresent(String.self, forKey: .artworkIdentifier)
    }
}

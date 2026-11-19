import SwiftUI
import Combine

/// View model managing state, validation, and persistence for adding and editing albums.
@MainActor
final class AlbumFormViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var artist: String = ""
    @Published var genre: Genre = .pop
    @Published var releaseYear: String = ""
    @Published var musicDirector: String = ""
    @Published var trackCount: String = ""
    @Published var favouriteTrack: String = ""
    @Published var notes: String = ""
    @Published var artworkIdentifier: String? = nil

    /// Whether this form is editing an existing album.
    let isEditing: Bool

    /// Preserved metadata for existing album.
    private let existingID: UUID?
    private let preservedDateAdded: Date?
    private let preservedListenCount: Int
    private let preservedIsFavourite: Bool

    /// Optional preset artworks available for selection.
    static let availableArtworkPresets: [String] = [
        "vinyl_classic",
        "vinyl_gold",
        "vinyl_neon",
        "vinyl_retro"
    ]

    /// Initializes form view model either for a new album or editing an existing one.
    /// - Parameter albumToEdit: Optional album instance to prefill.
    init(albumToEdit: Album? = nil) {
        if let album = albumToEdit {
            self.isEditing = true
            self.existingID = album.id
            self.preservedDateAdded = album.dateAdded
            self.preservedListenCount = album.listenCount
            self.preservedIsFavourite = album.isFavourite

            self.name = album.name
            self.artist = album.artist
            self.genre = album.genre
            self.releaseYear = String(album.releaseYear)
            self.musicDirector = album.musicDirector
            self.trackCount = String(album.trackCount)
            self.favouriteTrack = album.favouriteTrack
            self.notes = album.notes
            self.artworkIdentifier = album.artworkIdentifier
        } else {
            self.isEditing = false
            self.existingID = nil
            self.preservedDateAdded = nil
            self.preservedListenCount = 0
            self.preservedIsFavourite = false

            self.genre = .pop
            self.releaseYear = String(AlbumFormValidator.currentYear)
            self.trackCount = "10"
        }
    }

    // MARK: - Validation Properties

    /// Field-level validation error for album name.
    var nameError: String? {
        AlbumFormValidator.validateName(name)
    }

    /// Field-level validation error for artist name.
    var artistError: String? {
        AlbumFormValidator.validateArtist(artist)
    }

    /// Field-level validation error for release year.
    var yearError: String? {
        AlbumFormValidator.validateReleaseYear(releaseYear)
    }

    /// Field-level validation error for track count.
    var tracksError: String? {
        AlbumFormValidator.validateTrackCount(trackCount)
    }

    /// Whether the form is completely valid for submission.
    var isValid: Bool {
        AlbumFormValidator.isValid(
            name: name,
            artist: artist,
            releaseYear: releaseYear,
            trackCount: trackCount
        )
    }

    // MARK: - Build & Save Actions

    /// Constructs an Album instance from current form values if valid, preserving metadata if editing.
    /// - Returns: The built Album or nil if inputs are invalid.
    func buildAlbum() -> Album? {
        guard isValid,
              let year = Int(releaseYear.trimmingCharacters(in: .whitespacesAndNewlines)),
              let tracks = Int(trackCount.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }

        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDirector = musicDirector.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanFavTrack = favouriteTrack.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if isEditing, let id = existingID {
            return Album(
                id: id,
                name: cleanName,
                artist: cleanArtist,
                genre: genre,
                releaseYear: year,
                musicDirector: cleanDirector,
                trackCount: tracks,
                favouriteTrack: cleanFavTrack,
                listenCount: preservedListenCount,
                isFavourite: preservedIsFavourite,
                notes: cleanNotes,
                dateAdded: preservedDateAdded ?? Date(),
                artworkIdentifier: artworkIdentifier
            )
        } else {
            return Album(
                name: cleanName,
                artist: cleanArtist,
                genre: genre,
                releaseYear: year,
                musicDirector: cleanDirector,
                trackCount: tracks,
                favouriteTrack: cleanFavTrack,
                listenCount: 0,
                isFavourite: false,
                notes: cleanNotes,
                dateAdded: Date(),
                artworkIdentifier: artworkIdentifier
            )
        }
    }

    /// Validates inputs and saves the new or edited album into the central view model.
    /// - Parameter albumVM: The shared AlbumViewModel environment object.
    /// - Returns: True if saving succeeded.
    func save(into albumVM: AlbumViewModel) -> Bool {
        guard let album = buildAlbum() else {
            return false
        }

        if isEditing {
            albumVM.updateAlbum(album)
        } else {
            albumVM.addAlbum(album)
        }
        return true
    }
}

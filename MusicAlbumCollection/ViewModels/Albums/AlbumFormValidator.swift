import Foundation

/// Provides validation logic and field-level error messages for album creation and editing.
struct AlbumFormValidator {
    /// Minimum allowed release year.
    static let minimumYear: Int = 1900

    /// Returns the current calendar year.
    static var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    /// Validates the album name.
    /// - Parameter name: The user-entered album name.
    /// - Returns: An error message if invalid, or nil if valid.
    static func validateName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Album name is required."
        }
        return nil
    }

    /// Validates the artist name.
    /// - Parameter artist: The user-entered artist name.
    /// - Returns: An error message if invalid, or nil if valid.
    static func validateArtist(_ artist: String) -> String? {
        let trimmed = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Artist name is required."
        }
        return nil
    }

    /// Validates the release year.
    /// - Parameter yearString: The user-entered year string.
    /// - Returns: An error message if invalid, or nil if valid.
    static func validateReleaseYear(_ yearString: String) -> String? {
        let trimmed = yearString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Release year is required."
        }
        guard let year = Int(trimmed) else {
            return "Release year must be a valid number."
        }
        guard year >= minimumYear && year <= currentYear else {
            return "Release year must be between \(minimumYear) and \(currentYear)."
        }
        return nil
    }

    /// Validates the number of tracks.
    /// - Parameter trackString: The user-entered track count string.
    /// - Returns: An error message if invalid, or nil if valid.
    static func validateTrackCount(_ trackString: String) -> String? {
        let trimmed = trackString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Number of tracks is required."
        }
        guard let count = Int(trimmed) else {
            return "Track count must be a valid number."
        }
        guard count > 0 else {
            return "Track count must be greater than zero."
        }
        return nil
    }

    /// Checks if all required fields are valid.
    /// - Parameters:
    ///   - name: Album name.
    ///   - artist: Artist name.
    ///   - releaseYear: Release year string.
    ///   - trackCount: Track count string.
    /// - Returns: True if all fields satisfy validation rules.
    static func isValid(name: String, artist: String, releaseYear: String, trackCount: String) -> Bool {
        validateName(name) == nil &&
        validateArtist(artist) == nil &&
        validateReleaseYear(releaseYear) == nil &&
        validateTrackCount(trackCount) == nil
    }
}

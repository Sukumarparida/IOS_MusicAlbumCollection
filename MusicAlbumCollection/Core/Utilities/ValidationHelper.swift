import Foundation

/// Pure utility helpers for validating user input across the app.
enum ValidationHelper {
    /// Validates an album release year within the acceptable historical range.
    static func isValidReleaseYear(_ yearString: String) -> (isValid: Bool, error: String?) {
        let trimmed = yearString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return (false, nil) }
        guard let year = Int(trimmed) else {
            return (false, "Release year must be a valid number.")
        }
        let currentYear = Calendar.current.component(.year, from: Date())
        guard (AppConstants.Validation.minimumYear...currentYear).contains(year) else {
            return (false, "Enter a year between \(AppConstants.Validation.minimumYear) and \(currentYear).")
        }
        return (true, nil)
    }

    /// Validates an album track count.
    static func isValidTrackCount(_ trackCountString: String) -> (isValid: Bool, error: String?) {
        let trimmed = trackCountString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return (false, nil) }
        guard let tracks = Int(trimmed), tracks >= AppConstants.Validation.minimumTrackCount else {
            return (false, "Tracks must be a number greater than 0.")
        }
        return (true, nil)
    }

    /// Validates username input for manual authentication.
    static func validateUsername(_ username: String) -> String? {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Please enter a username."
        }
        if trimmed.count < AppConstants.Validation.minimumUsernameLength {
            return "Username must be at least \(AppConstants.Validation.minimumUsernameLength) characters."
        }
        return nil
    }

    /// Validates password input for manual authentication.
    static func validatePassword(_ password: String) -> String? {
        if password.isEmpty {
            return "Please enter a password."
        }
        if password.count < AppConstants.Validation.minimumPasswordLength {
            return "Password must be at least \(AppConstants.Validation.minimumPasswordLength) characters."
        }
        return nil
    }
}

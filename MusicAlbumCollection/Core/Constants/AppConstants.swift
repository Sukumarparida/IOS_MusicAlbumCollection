import Foundation

/// Application-wide constants grouped by domain.
enum AppConstants {
    enum Storage {
        static let savedAlbumsKey = "savedAlbums"
    }

    enum Validation {
        static let minimumYear = 1900
        static let minimumUsernameLength = 3
        static let minimumPasswordLength = 4
        static let minimumTrackCount = 1
    }

    enum Auth {
        static let biometricReason = "Authenticate to open your music collection"
        static let biometricCancelTitle = "Use Login Instead"
    }

    enum UI {
        static let defaultCornerRadius: CGFloat = 14
        static let cardPadding: CGFloat = 12
        static let statCardVerticalPadding: CGFloat = 14
        static let miniCardWidth: CGFloat = 160
    }
}

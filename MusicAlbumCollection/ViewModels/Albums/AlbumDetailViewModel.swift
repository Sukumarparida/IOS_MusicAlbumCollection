import SwiftUI
import Combine

/// View model managing album detail view presentation, state changes, and interactions.
@MainActor
final class AlbumDetailViewModel: ObservableObject {
    /// The unique identifier of the album being displayed.
    let albumID: UUID

    /// The current album instance, if available in the repository.
    @Published private(set) var album: Album?

    /// Flag indicating whether a listen action is currently being debounced/animated.
    @Published var isProcessingListen: Bool = false

    /// Temporary flag indicating that a listen event was just recorded.
    @Published var justRecordedListen: Bool = false

    /// Controls presentation of the edit album sheet.
    @Published var showingEditSheet: Bool = false

    /// Controls presentation of the delete confirmation alert.
    @Published var showingDeleteAlert: Bool = false

    private let repository: AlbumRepository
    private weak var albumViewModel: AlbumViewModel?
    private var cancellables = Set<AnyCancellable>()

    /// Date formatter for displaying album date added.
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// Initializes the view model with an album UUID and optional repository.
    /// - Parameters:
    ///   - albumID: The UUID of the album to load.
    ///   - repository: Optional album repository; defaults to DefaultAlbumRepository.
    init(albumID: UUID, repository: AlbumRepository? = nil) {
        self.albumID = albumID
        let repo = repository ?? DefaultAlbumRepository()
        self.repository = repo
        self.album = repo.getAlbum(by: albumID)
    }

    /// Convenience initializer starting with an existing Album instance.
    /// - Parameters:
    ///   - album: The album model.
    ///   - repository: Optional album repository; defaults to DefaultAlbumRepository.
    convenience init(album: Album, repository: AlbumRepository? = nil) {
        self.init(albumID: album.id, repository: repository)
        self.album = album
    }

    /// Binds this view model to the shared AlbumViewModel to observe global updates reactively.
    /// - Parameter albumViewModel: The environment AlbumViewModel.
    func bind(to albumViewModel: AlbumViewModel) {
        self.albumViewModel = albumViewModel
        cancellables.removeAll()

        albumViewModel.$albums
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)

        refresh()
    }

    /// Refreshes the local album model from the repository or environment view model.
    func refresh() {
        if let albumViewModel {
            self.album = albumViewModel.album(withID: albumID)
        } else {
            self.album = repository.getAlbum(by: albumID)
        }
    }

    // MARK: - Formatted Presentation Properties

    /// The display title of the album.
    var name: String {
        album?.name ?? "Unknown Album"
    }

    /// The artist name of the album.
    var artist: String {
        album?.artist ?? "Unknown Artist"
    }

    /// The genre display name.
    var genre: Genre {
        album?.genre ?? .other
    }

    /// The genre display string.
    var genreName: String {
        album?.genre.rawValue ?? "Unknown"
    }

    /// The release year formatted as a string.
    var releaseYearString: String {
        guard let album else { return "-" }
        return String(album.releaseYear)
    }

    /// The music director name or fallback dash.
    var musicDirector: String {
        guard let director = album?.musicDirector, !director.isEmpty else {
            return "-"
        }
        return director
    }

    /// The total track count formatted as a string.
    var trackCountString: String {
        guard let album else { return "0" }
        return String(album.trackCount)
    }

    /// The favorite track title or fallback dash.
    var favouriteTrack: String {
        guard let track = album?.favouriteTrack, !track.isEmpty else {
            return "-"
        }
        return track
    }

    /// Current listen count.
    var listenCount: Int {
        album?.listenCount ?? 0
    }

    /// Whether this album is marked as a favourite.
    var isFavourite: Bool {
        album?.isFavourite ?? false
    }

    /// Notes attached to the album, or default empty placeholder.
    var notes: String {
        guard let notes = album?.notes, !notes.isEmpty else {
            return "No notes."
        }
        return notes
    }

    /// Formatted date string for when this album was added to the collection.
    var formattedDateAdded: String {
        guard let date = album?.dateAdded else { return "-" }
        return Self.dateFormatter.string(from: date)
    }

    /// Artwork preset or asset identifier.
    var artworkIdentifier: String? {
        album?.artworkIdentifier
    }

    // MARK: - User Actions

    /// Records a listen for the album with debounce protection and haptic feedback.
    func recordListen() {
        guard !isProcessingListen, let currentAlbum = album else { return }
        isProcessingListen = true
        justRecordedListen = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if let albumViewModel {
            albumViewModel.incrementListenCount(currentAlbum)
        } else {
            repository.incrementListenCount(id: currentAlbum.id)
            refresh()
        }

        Task {
            try? await Task.sleep(nanoseconds: 750_000_000)
            withAnimation {
                self.justRecordedListen = false
                self.isProcessingListen = false
            }
        }
    }

    /// Toggles the favourite status of this album.
    func toggleFavourite() {
        guard let currentAlbum = album else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            if let albumViewModel {
                albumViewModel.toggleFavourite(currentAlbum)
            } else {
                repository.toggleFavourite(id: currentAlbum.id)
                refresh()
            }
        }
    }

    /// Permanently deletes this album from local persistence.
    /// - Returns: True if deletion was triggered.
    @discardableResult
    func deleteAlbum() -> Bool {
        guard let currentAlbum = album else { return false }
        if let albumViewModel {
            albumViewModel.deleteAlbum(currentAlbum)
        } else {
            repository.deleteAlbum(id: currentAlbum.id)
        }
        self.album = nil
        return true
    }
}

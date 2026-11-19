import SwiftUI

/// Shared form for adding a new album (albumToEdit == nil) or editing an existing one.
struct AlbumFormView: View {
    @EnvironmentObject var albumVM: AlbumViewModel
    @Environment(\.dismiss) private var dismiss

    let albumToEdit: Album?

    @State private var name: String
    @State private var artist: String
    @State private var genre: Genre
    @State private var musicDirector: String
    @State private var releaseYear: String
    @State private var trackCount: String
    @State private var favouriteTrack: String
    @State private var notes: String

    /// Pre-fills the fields when editing, or starts empty when adding.
    init(albumToEdit: Album?) {
        self.albumToEdit = albumToEdit
        _name = State(initialValue: albumToEdit?.name ?? "")
        _artist = State(initialValue: albumToEdit?.artist ?? "")
        _genre = State(initialValue: albumToEdit?.genre ?? .pop)
        _musicDirector = State(initialValue: albumToEdit?.musicDirector ?? "")
        _releaseYear = State(initialValue: albumToEdit.map { String($0.releaseYear) } ?? "")
        _trackCount = State(initialValue: albumToEdit.map { String($0.trackCount) } ?? "")
        _favouriteTrack = State(initialValue: albumToEdit?.favouriteTrack ?? "")
        _notes = State(initialValue: albumToEdit?.notes ?? "")
    }

    // MARK: - Validation

    private var yearValidation: (isValid: Bool, error: String?) {
        ValidationHelper.isValidReleaseYear(releaseYear)
    }

    private var tracksValidation: (isValid: Bool, error: String?) {
        ValidationHelper.isValidTrackCount(trackCount)
    }

    private var yearError: String? {
        releaseYear.isEmpty ? nil : yearValidation.error
    }

    private var tracksError: String? {
        trackCount.isEmpty ? nil : tracksValidation.error
    }

    private var isValid: Bool {
        let hasName = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasArtist = !artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasName && hasArtist && yearValidation.isValid && tracksValidation.isValid
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Album") {
                    TextField("Album name (required)", text: $name)
                    TextField("Artist (required)", text: $artist)
                    Picker("Genre", selection: $genre) {
                        ForEach(Genre.allCases) { genre in
                            Text(genre.rawValue).tag(genre)
                        }
                    }
                }

                Section {
                    TextField("Music director", text: $musicDirector)
                    TextField("Release year (required)", text: $releaseYear)
                        .keyboardType(.numberPad)
                    TextField("Number of tracks (required)", text: $trackCount)
                        .keyboardType(.numberPad)
                    TextField("Favourite track", text: $favouriteTrack)
                } header: {
                    Text("Details")
                } footer: {
                    VStack(alignment: .leading, spacing: 2) {
                        if let message = yearError { Text(message) }
                        if let message = tracksError { Text(message) }
                    }
                    .foregroundStyle(.red)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(albumToEdit == nil ? "Add Album" : "Edit Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Actions

    /// Creates a new album or updates the existing one, then closes the form.
    private func save() {
        guard let year = Int(releaseYear.trimmingCharacters(in: .whitespacesAndNewlines)),
              let tracks = Int(trackCount.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }

        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)

        if var existing = albumToEdit {
            existing.name = cleanName
            existing.artist = cleanArtist
            existing.genre = genre
            existing.musicDirector = musicDirector
            existing.releaseYear = year
            existing.trackCount = tracks
            existing.favouriteTrack = favouriteTrack
            existing.notes = notes
            albumVM.updateAlbum(existing)
        } else {
            let newAlbum = Album(
                name: cleanName,
                artist: cleanArtist,
                genre: genre,
                releaseYear: year,
                musicDirector: musicDirector,
                trackCount: tracks,
                favouriteTrack: favouriteTrack,
                notes: notes
            )
            albumVM.addAlbum(newAlbum)
        }
        dismiss()
    }
}

#Preview {
    AlbumFormView(albumToEdit: nil)
        .environmentObject(AlbumViewModel())
}

import SwiftUI

/// Screen presenting the form for modifying an existing album entry while preserving critical metadata.
struct EditAlbumView: View {
    @EnvironmentObject var albumVM: AlbumViewModel
    @Environment(\.dismiss) private var dismiss

    let album: Album
    @StateObject private var viewModel: AlbumFormViewModel

    /// Initializes EditAlbumView with the album to edit.
    /// - Parameter album: The existing album being modified.
    init(album: Album) {
        self.album = album
        _viewModel = StateObject(wrappedValue: AlbumFormViewModel(albumToEdit: album))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Basic Info (Name, Artist, Genre)
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Album Name (required)", text: $viewModel.name)
                        if let error = viewModel.nameError, !viewModel.name.isEmpty {
                            Text(error)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Artist Name (required)", text: $viewModel.artist)
                        if let error = viewModel.artistError, !viewModel.artist.isEmpty {
                            Text(error)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }

                    Picker("Genre", selection: $viewModel.genre) {
                        ForEach(Genre.allCases) { genre in
                            Text(genre.rawValue).tag(genre)
                        }
                    }
                } header: {
                    Text("Album Information")
                }

                // Section 2: Production Details (Release Year, Director, Tracks, Fav Track)
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Release Year (required)", text: $viewModel.releaseYear)
                            .keyboardType(.numberPad)
                        if let error = viewModel.yearError {
                            Text(error)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }

                    TextField("Music Director", text: $viewModel.musicDirector)

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Number of Tracks (required)", text: $viewModel.trackCount)
                            .keyboardType(.numberPad)
                        if let error = viewModel.tracksError {
                            Text(error)
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                    }

                    TextField("Favourite Track", text: $viewModel.favouriteTrack)
                } header: {
                    Text("Production & Tracks")
                }

                // Section 3: Optional Album Artwork Selection
                Section {
                    artworkPickerView
                } header: {
                    Text("Album Artwork")
                }

                // Section 4: Notes
                Section("Notes") {
                    TextField("Notes", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Section 5: Preserved Metadata Summary
                Section {
                    HStack {
                        Text("Listens")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(album.listenCount)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Favourite")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(album.isFavourite ? "Yes" : "No")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Preserved Stats")
                } footer: {
                    Text("Album ID, date added, play counts, and favourite status are preserved.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.save(into: albumVM) {
                            dismiss()
                        }
                    }
                    .bold()
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }

    // MARK: - Artwork Picker

    private var artworkPickerView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button {
                    viewModel.artworkIdentifier = nil
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.accentColor.opacity(0.15))
                                .frame(width: 56, height: 56)
                            Image(systemName: "opticaldisc.fill")
                                .font(.title2)
                                .foregroundStyle(Color.accentColor)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(viewModel.artworkIdentifier == nil ? Color.accentColor : Color.clear, lineWidth: 2)
                        )

                        Text("Default")
                            .font(.caption2)
                            .foregroundStyle(viewModel.artworkIdentifier == nil ? .primary : .secondary)
                    }
                }
                .buttonStyle(.plain)

                ForEach(AlbumFormViewModel.availableArtworkPresets, id: \.self) { preset in
                    Button {
                        viewModel.artworkIdentifier = preset
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(presetGradient(preset))
                                    .frame(width: 56, height: 56)
                                Image(systemName: presetIcon(preset))
                                    .font(.title3)
                                    .foregroundStyle(.white)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(viewModel.artworkIdentifier == preset ? Color.accentColor : Color.clear, lineWidth: 2)
                            )

                            Text(presetTitle(preset))
                                .font(.caption2)
                                .foregroundStyle(viewModel.artworkIdentifier == preset ? .primary : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func presetGradient(_ preset: String) -> LinearGradient {
        switch preset {
        case "vinyl_classic":
            return LinearGradient(colors: [Color.black, Color.gray], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "vinyl_gold":
            return LinearGradient(colors: [Color.orange, Color.yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "vinyl_neon":
            return LinearGradient(colors: [Color.purple, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "vinyl_retro":
            return LinearGradient(colors: [Color.brown, Color.orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [Color.blue, Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func presetIcon(_ preset: String) -> String {
        switch preset {
        case "vinyl_classic": return "music.note"
        case "vinyl_gold": return "star.fill"
        case "vinyl_neon": return "sparkles"
        case "vinyl_retro": return "guitars"
        default: return "opticaldisc"
        }
    }

    private func presetTitle(_ preset: String) -> String {
        switch preset {
        case "vinyl_classic": return "Classic"
        case "vinyl_gold": return "Gold"
        case "vinyl_neon": return "Neon"
        case "vinyl_retro": return "Retro"
        default: return "Preset"
        }
    }
}

#Preview {
    EditAlbumView(
        album: Album(
            name: "Roja",
            artist: "A. R. Rahman",
            genre: .film,
            releaseYear: 1992,
            musicDirector: "A. R. Rahman",
            trackCount: 6
        )
    )
    .environmentObject(AlbumViewModel())
}

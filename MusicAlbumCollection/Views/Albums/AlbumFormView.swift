import SwiftUI

/// Unified wrapper view for adding or editing an album, routing to AddAlbumView or EditAlbumView.
struct AlbumFormView: View {
    let albumToEdit: Album?

    var body: some View {
        if let album = albumToEdit {
            EditAlbumView(album: album)
        } else {
            AddAlbumView()
        }
    }
}

#Preview("Add Album") {
    AlbumFormView(albumToEdit: nil)
        .environmentObject(AlbumViewModel())
}

#Preview("Edit Album") {
    AlbumFormView(
        albumToEdit: Album(
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

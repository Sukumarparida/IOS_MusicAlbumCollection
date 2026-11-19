import SwiftUI

/// Dedicated view displaying the user's favourite albums, wrapping FavouriteView.
struct FavouritesView: View {
    var body: some View {
        FavouriteView()
    }
}

#Preview {
    FavouritesView()
        .environmentObject(AlbumViewModel())
}

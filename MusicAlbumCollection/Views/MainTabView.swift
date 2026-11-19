import SwiftUI

/// Main navigation tab bar: Dashboard, all Albums, Favourites, and Settings.
struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }

            AlbumListView(favouritesOnly: false)
                .tabItem { Label("Albums", systemImage: "music.note.list") }

            FavouriteView()
                .tabItem { Label("Favourites", systemImage: "heart.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(AlbumViewModel())
}

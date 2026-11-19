import SwiftUI

/// App entry point. Creates the AppCoordinator managing dependency injection and root flow.
@main
struct MusicAlbumCollectionApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView(coordinator: coordinator)
        }
    }
}

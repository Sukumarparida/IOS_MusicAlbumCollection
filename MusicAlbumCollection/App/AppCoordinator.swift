import SwiftUI
import Combine

/// AppCoordinator manages the top-level application flow, state, and dependency injection.
@MainActor
final class AppCoordinator: ObservableObject {
    @Published var authViewModel: AuthenticationViewModel
    @Published var albumViewModel: AlbumViewModel
    let albumRepository: AlbumRepository

    init(
        authViewModel: AuthenticationViewModel? = nil,
        albumRepository: AlbumRepository? = nil
    ) {
        let repo = albumRepository ?? DefaultAlbumRepository()
        self.albumRepository = repo
        self.albumViewModel = AlbumViewModel(repository: repo)
        self.authViewModel = authViewModel ?? AuthenticationViewModel()
    }
}

/// Root coordinator view switching between unauthenticated AuthenticationView and authenticated MainTabView.
struct AppCoordinatorView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        Group {
            if coordinator.authViewModel.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView(viewModel: coordinator.authViewModel)
            }
        }
        .environmentObject(coordinator.authViewModel)
        .environmentObject(coordinator.albumViewModel)
    }
}

#Preview {
    AppCoordinatorView(coordinator: AppCoordinator())
}

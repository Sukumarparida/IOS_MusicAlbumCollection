import SwiftUI

/// Displays a scrollable list of albums with real-time search, genre filtering, sorting, swipe-to-delete, and album creation.
struct AlbumListView: View {
    @EnvironmentObject var albumVM: AlbumViewModel

    let favouritesOnly: Bool
    @StateObject private var viewModel: AlbumListViewModel

    /// Initializes AlbumListView with an optional favouritesOnly filter flag.
    /// - Parameter favouritesOnly: When true, restricts list strictly to starred albums.
    init(favouritesOnly: Bool = false) {
        self.favouritesOnly = favouritesOnly
        _viewModel = StateObject(wrappedValue: AlbumListViewModel(favouritesOnly: favouritesOnly))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Active Filter Chips Bar
                if viewModel.activeFilterCount > 0 {
                    activeFilterChipsBar
                }

                // Main Content List or Empty State
                Group {
                    if viewModel.isEmpty {
                        emptyView
                    } else {
                        List {
                            ForEach(viewModel.displayedAlbums) { album in
                                NavigationLink(value: album.id) {
                                    AlbumCardView(album: album)
                                }
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                            .onDelete { offsets in
                                viewModel.deleteAlbums(at: offsets)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle(viewModel.navigationTitle)
            .searchable(text: $viewModel.searchText, prompt: "Search albums or artists")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filterToolbarButton
                }

                if !favouritesOnly {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.showingAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add Album")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingFilterSheet) {
                AlbumFilterView(
                    selectedGenre: $viewModel.selectedGenre,
                    sortOption: $viewModel.sortOption
                )
            }
            .sheet(isPresented: $viewModel.showingAddSheet) {
                AddAlbumView()
            }
            .navigationDestination(for: UUID.self) { id in
                AlbumDetailView(albumID: id)
            }
            .onAppear {
                viewModel.bind(to: albumVM)
            }
        }
    }

    // MARK: - Toolbar Controls

    private var filterToolbarButton: some View {
        Menu {
            // Filter & Sort Sheet launcher
            Button {
                viewModel.showingFilterSheet = true
            } label: {
                Label("Filter & Sort Options...", systemImage: "slider.horizontal.3")
            }

            Divider()

            // Quick Genre selection submenu
            Menu {
                Button {
                    viewModel.selectedGenre = nil
                } label: {
                    HStack {
                        Text("All Genres")
                        if viewModel.selectedGenre == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Divider()

                ForEach(Genre.allCases) { genre in
                    Button {
                        viewModel.selectedGenre = genre
                    } label: {
                        HStack {
                            Text(genre.rawValue)
                            if viewModel.selectedGenre == genre {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label(
                    viewModel.selectedGenre?.rawValue ?? "Genre: All",
                    systemImage: "music.quarternote.3"
                )
            }

            // Quick Sort selection submenu
            Menu {
                ForEach(AlbumSortOption.allCases) { option in
                    Button {
                        viewModel.sortOption = option
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if viewModel.sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Sort: \(viewModel.sortOption.rawValue)", systemImage: "arrow.up.arrow.down")
            }

            if viewModel.activeFilterCount > 0 {
                Divider()

                Button(role: .destructive) {
                    viewModel.clearFilters()
                } label: {
                    Label("Clear Filters", systemImage: "arrow.counterclockwise")
                }
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: viewModel.activeFilterCount > 0 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.body)

                if viewModel.activeFilterCount > 0 {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .accessibilityLabel("Filter and sort")
    }

    // MARK: - Active Filter Chips Bar

    private var activeFilterChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let genre = viewModel.selectedGenre {
                    filterChip(title: genre.rawValue, systemImage: "music.note") {
                        viewModel.selectedGenre = nil
                    }
                }

                if viewModel.sortOption != .recentlyAdded {
                    filterChip(title: viewModel.sortOption.rawValue, systemImage: viewModel.sortOption.systemImage) {
                        viewModel.sortOption = .recentlyAdded
                    }
                }

                Button {
                    viewModel.clearFilters()
                } label: {
                    Text("Clear All")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .background(Color(.secondarySystemBackground))
    }

    private func filterChip(title: String, systemImage: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.caption2)
            Text(title)
                .font(.caption2.weight(.medium))
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.12), in: Capsule())
        .foregroundStyle(Color.accentColor)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 16) {
            EmptyStateView(
                title: viewModel.emptyTitle,
                systemImage: viewModel.emptyIcon,
                description: viewModel.emptyDescription
            )

            if viewModel.isSearchingOrFiltering {
                Button("Clear Search & Filters") {
                    viewModel.resetAll()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview("All Albums") {
    AlbumListView(favouritesOnly: false)
        .environmentObject(AlbumViewModel())
}

#Preview("Favourites") {
    AlbumListView(favouritesOnly: true)
        .environmentObject(AlbumViewModel())
}

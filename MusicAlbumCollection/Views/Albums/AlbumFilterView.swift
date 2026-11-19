import SwiftUI

/// Sheet interface allowing users to configure genre filtering and collection sorting options.
struct AlbumFilterView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedGenre: Genre?
    @Binding var sortOption: AlbumSortOption

    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Genre Filter
                Section {
                    Button {
                        selectedGenre = nil
                    } label: {
                        HStack {
                            Text("All Genres")
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedGenre == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                    }

                    ForEach(Genre.allCases) { genre in
                        Button {
                            selectedGenre = genre
                        } label: {
                            HStack {
                                Text(genre.rawValue)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedGenre == genre {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Genre Filter")
                } footer: {
                    Text("Filter your collection by selecting a single musical genre or All Genres.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Section 2: Sorting Options
                Section {
                    ForEach(AlbumSortOption.allCases) { option in
                        Button {
                            sortOption = option
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: option.systemImage)
                                    .frame(width: 24)
                                    .foregroundStyle(sortOption == option ? Color.accentColor : .secondary)

                                Text(option.rawValue)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Sorting")
                } footer: {
                    Text("Change how albums are ordered across the list.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Section 3: Reset Action
                if hasActiveFilters {
                    Section {
                        Button(role: .destructive) {
                            withAnimation {
                                selectedGenre = nil
                                sortOption = .recentlyAdded
                            }
                        } label: {
                            HStack {
                                Spacer()
                                Label("Clear Filters & Reset Sorting", systemImage: "arrow.counterclockwise")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }

    /// Whether any non-default filter or sorting option is currently chosen.
    private var hasActiveFilters: Bool {
        selectedGenre != nil || sortOption != .recentlyAdded
    }
}

#Preview {
    AlbumFilterView(
        selectedGenre: .constant(.film),
        sortOption: .constant(.recentlyAdded)
    )
}

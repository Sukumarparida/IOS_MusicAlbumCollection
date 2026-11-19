import SwiftUI

/// Responsive search bar component providing real-time text input, a clear button, and filter sheet shortcut.
struct AlbumSearchView: View {
    @Binding var searchText: String
    var activeFilterCount: Int = 0
    var onFilterTapped: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Search Input Container
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search by album or artist", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Filter Button
            if let onFilterTapped {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onFilterTapped()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: activeFilterCount > 0 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .font(.system(size: 22))
                            .foregroundStyle(activeFilterCount > 0 ? Color.accentColor : .primary)
                            .padding(6)

                        if activeFilterCount > 0 {
                            Text("\(activeFilterCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(4)
                                .background(Color.accentColor, in: Circle())
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                .accessibilityLabel("Filter and sort options")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 16) {
        AlbumSearchView(
            searchText: .constant("Beatles"),
            activeFilterCount: 2,
            onFilterTapped: {}
        )

        AlbumSearchView(
            searchText: .constant(""),
            activeFilterCount: 0,
            onFilterTapped: {}
        )
    }
}

import SwiftUI

/// Reusable empty state view wrapping ContentUnavailableView.
struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(description)
        }
    }
}

#Preview {
    EmptyStateView(
        title: "No Albums",
        systemImage: "music.note",
        description: "Tap the '+' button above to add your first album."
    )
}

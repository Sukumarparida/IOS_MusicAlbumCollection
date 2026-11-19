import SwiftUI

/// Reusable view and view modifier providing consistent album deletion confirmation alerts.
struct DeleteConfirmationAlertModifier: ViewModifier {
    let albumName: String
    @Binding var isPresented: Bool
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("Delete Album?", isPresented: $isPresented) {
                Button("Delete", role: .destructive) {
                    onDelete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete \"\(albumName)\"? This action cannot be undone.")
            }
    }
}

extension View {
    /// Attaches an album deletion confirmation alert.
    /// - Parameters:
    ///   - isPresented: Binding to control alert presentation.
    ///   - albumName: Title of the album being deleted.
    ///   - onDelete: Action executed when confirmed.
    /// - Returns: A view wrapped with the confirmation dialog.
    func deleteAlbumConfirmation(
        isPresented: Binding<Bool>,
        albumName: String,
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(DeleteConfirmationAlertModifier(
            albumName: albumName,
            isPresented: isPresented,
            onDelete: onDelete
        ))
    }
}

/// Standalone visual confirmation card view for destructive deletion operations.
struct DeleteConfirmationView: View {
    let albumName: String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "trash.fill")
                    .font(.title)
                    .foregroundStyle(.red)
            }

            VStack(spacing: 6) {
                Text("Delete \"\(albumName)\"?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text("This will permanently remove the album from your library and storage.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                Button("Delete", role: .destructive) {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 4)
        .padding(24)
    }
}

#Preview {
    DeleteConfirmationView(
        albumName: "Abbey Road",
        onConfirm: {},
        onCancel: {}
    )
}

import SwiftUI

extension View {
    /// Applies standard rounded card styling with secondary system background.
    func cardStyle(cornerRadius: CGFloat = AppConstants.UI.defaultCornerRadius) -> some View {
        self
            .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Dismisses the keyboard on tap outside input fields.
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

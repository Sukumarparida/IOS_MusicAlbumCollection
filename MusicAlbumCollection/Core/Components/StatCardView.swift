import SwiftUI

/// A modern statistic card displaying a metric, title, and themed icon with subtle shadows.
struct StatCardView: View {
    let title: String
    let value: Int
    let icon: String
    var accentColor: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(accentColor)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(value)")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: value)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

#Preview {
    HStack(spacing: 12) {
        StatCardView(title: "Total Albums", value: 12, icon: "opticaldisc.fill", accentColor: .purple)
        StatCardView(title: "Total Artists", value: 8, icon: "person.2.fill", accentColor: .blue)
    }
    .padding()
}

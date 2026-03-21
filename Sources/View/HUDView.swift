import SwiftUI

struct HUDView: View {
    let levelNumber: Int
    let moveCount: Int
    let onRestart: () -> Void
    var onLevelSelect: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            if let onLevelSelect {
                Button(action: onLevelSelect) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.title3)
                        .foregroundStyle(iconColor)
                        .frame(width: 36, height: 36)
                        .background(buttonBackgroundColor)
                        .clipShape(Circle())
                }
                .frame(width: 44, height: 44)
            }

            Text("Level \(levelNumber)")
                .font(.headline.weight(.semibold))
                .foregroundStyle(primaryTextColor)

            Spacer()

            Text("Moves: \(moveCount)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(secondaryTextColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(pillBackgroundColor)
                .clipShape(Capsule())

            Spacer()

            Button(action: onRestart) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(iconColor)
                    .frame(width: 36, height: 36)
                    .background(buttonBackgroundColor)
                    .clipShape(Circle())
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark
            ? Color(white: 0.88)
            : Color(red: 0.22, green: 0.20, blue: 0.18)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? Color(white: 0.65)
            : Color(red: 0.40, green: 0.37, blue: 0.35)
    }

    private var iconColor: Color {
        colorScheme == .dark
            ? Color(white: 0.78)
            : Color(red: 0.30, green: 0.27, blue: 0.24)
    }

    private var buttonBackgroundColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
    }

    private var pillBackgroundColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.black.opacity(0.04)
    }
}

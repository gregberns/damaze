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
                        .font(.title2)
                        .foregroundStyle(primaryTextColor)
                }
                .frame(width: 44, height: 44)
            }

            Text("Level \(levelNumber)")
                .font(.headline)
                .foregroundStyle(primaryTextColor)

            Spacer()

            Text("Moves: \(moveCount)")
                .font(.headline)
                .foregroundStyle(secondaryTextColor)

            Spacer()

            Button(action: onRestart) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title2)
                    .foregroundStyle(primaryTextColor)
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark
            ? Color(white: 0.85)
            : Color(red: 0.25, green: 0.22, blue: 0.20)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? Color(white: 0.6)
            : Color(red: 0.45, green: 0.42, blue: 0.40)
    }
}

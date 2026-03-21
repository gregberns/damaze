import SwiftUI

struct HUDView: View {
    let levelNumber: Int
    let moveCount: Int
    let onRestart: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            Text("Level \(levelNumber)")
                .font(.headline)
                .foregroundStyle(primaryTextColor)

            Spacer()

            Text("Moves: \(moveCount)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(secondaryTextColor)

            Spacer()

            Button(action: onRestart) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title2)
                    .foregroundStyle(secondaryTextColor)
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
    }

    private var primaryTextColor: Color {
        colorScheme == .dark
            ? Color(white: 0.85)
            : Color(white: 0.2)
    }

    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? Color(white: 0.55)
            : Color(white: 0.4)
    }
}

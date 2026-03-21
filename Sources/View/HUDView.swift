import SwiftUI

struct HUDView: View {
    let levelNumber: Int
    let moveCount: Int
    let onRestart: () -> Void
    var onLevelSelect: (() -> Void)?

    var body: some View {
        HStack {
            if let onLevelSelect {
                Button(action: onLevelSelect) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.title2)
                }
                .frame(width: 44, height: 44)
            }

            Text("Level \(levelNumber)")
                .font(.headline)

            Spacer()

            Text("Moves: \(moveCount)")
                .font(.headline)

            Spacer()

            Button(action: onRestart) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title2)
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
    }
}

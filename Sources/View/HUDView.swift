import SwiftUI

struct HUDView: View {
    let levelNumber: Int
    let moveCount: Int
    let onRestart: () -> Void

    var body: some View {
        HStack {
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

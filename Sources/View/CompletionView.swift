import SwiftUI

struct CompletionView: View {
    let onPlayAgain: () -> Void
    var onLevelSelect: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Text("Congratulations!")
                .font(.largeTitle.bold())

            Text("You completed all levels.")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Thanks for playing Damaze")
                .font(.body)
                .foregroundStyle(.secondary)

            Button("Play Again", action: onPlayAgain)
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.top, 8)

            if let onLevelSelect {
                Button("Level Select", action: onLevelSelect)
                    .buttonStyle(.bordered)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

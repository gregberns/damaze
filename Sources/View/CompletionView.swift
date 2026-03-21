import SwiftUI

struct CompletionView: View {
    let onPlayAgain: () -> Void

    @Environment(\.colorScheme) private var colorScheme

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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            completionBackground
                .ignoresSafeArea()
        }
    }

    private var completionBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.06, green: 0.06, blue: 0.08)
            : Color(red: 0.95, green: 0.93, blue: 0.90)
    }
}

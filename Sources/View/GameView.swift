import SwiftUI

extension LevelColorScheme {
    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        }
    }
}

struct GameView: View {
    @Bindable var viewModel: GameViewModel

    var body: some View {
        if viewModel.isShowingCompletion {
            CompletionView(onPlayAgain: viewModel.playAgain)
                .transition(.opacity)
        } else {
            let levelData = LevelStore.allLevels[viewModel.currentLevelIndex]
            let levelColor = levelData.colorScheme.color

            ZStack {
                VStack(spacing: 0) {
                    HUDView(
                        levelNumber: viewModel.currentLevelIndex + 1,
                        moveCount: viewModel.moveCount,
                        onRestart: viewModel.restart
                    )
                    .padding(.top, 8)

                    GridView(
                        level: viewModel.currentLevel,
                        paintedTiles: viewModel.visuallyPaintedTiles,
                        ballPosition: viewModel.animatingBallPosition,
                        levelColor: levelColor,
                        isBumping: viewModel.isBumping,
                        bumpDirection: viewModel.bumpDirection,
                        shouldPulse: viewModel.shouldPulse,
                        isGridPulsing: viewModel.isGridPulsing
                    )
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                if let direction = InputMapper.direction(from: value.translation) {
                                    viewModel.handleSwipe(direction: direction)
                                }
                            }
                    )
                }

                // Win text overlay
                if viewModel.isShowingWinText {
                    VStack(spacing: 8) {
                        Text("Level Complete!")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)

                        Text("Moves: \(viewModel.winMoveCount)")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                    }
                    .transition(.opacity)
                }
            }
            .background(Color(.systemBackground))
        }
    }
}

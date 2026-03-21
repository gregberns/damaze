import SwiftUI

extension LevelColorScheme {
    var color: Color {
        switch self {
        case .blue: return Color(red: 0.25, green: 0.52, blue: 0.95)
        case .green: return Color(red: 0.20, green: 0.78, blue: 0.45)
        case .orange: return Color(red: 0.98, green: 0.58, blue: 0.15)
        case .purple: return Color(red: 0.62, green: 0.35, blue: 0.90)
        case .teal: return Color(red: 0.18, green: 0.75, blue: 0.72)
        case .red: return Color(red: 0.95, green: 0.28, blue: 0.30)
        }
    }
}

struct GameView: View {
    @Bindable var viewModel: GameViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if viewModel.isShowingCompletion {
            CompletionView(onPlayAgain: viewModel.playAgain, onLevelSelect: viewModel.showLevelSelect)
                .transition(.opacity)
        } else {
            let levelData = LevelStore.allLevels[viewModel.currentLevelIndex]
            let levelColor = levelData.colorScheme.color

            ZStack {
                backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    HUDView(
                        levelNumber: viewModel.currentLevelIndex + 1,
                        moveCount: viewModel.moveCount,
                        onRestart: viewModel.restart,
                        onLevelSelect: viewModel.showLevelSelect
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
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.10, green: 0.09, blue: 0.08)
            : Color(red: 0.96, green: 0.94, blue: 0.90)
    }
}

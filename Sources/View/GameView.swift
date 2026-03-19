import SwiftUI

struct GameView: View {
    @Bindable var viewModel: GameViewModel

    var body: some View {
        let levelData = LevelStore.allLevels[viewModel.currentLevelIndex]
        let levelColor = levelData.colorScheme.color

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
                shouldPulse: viewModel.shouldPulse
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
        .background(Color(.systemBackground))
    }
}

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
                paintedTiles: viewModel.paintedTiles,
                ballPosition: viewModel.animatingBallPosition,
                levelColor: levelColor
            )
        }
        .background(Color(.systemBackground))
    }
}

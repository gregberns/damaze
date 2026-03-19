import SwiftUI

@Observable
class GameViewModel {
    // Core state
    var gameState: GameState
    var currentLevelIndex: Int
    var isShowingCompletion: Bool

    // Animation state (view-layer, not model)
    var animatingBallPosition: GridPosition
    var bufferedDirection: Direction?
    var isBumping: Bool
    var bumpDirection: Direction?
    var isAnimatingMovement: Bool

    // Paint animation: tracks which tiles have been visually painted (for sequencing)
    var visuallyPaintedTiles: Set<GridPosition>

    // Computed properties
    var currentLevel: Level { gameState.level }
    var ballPosition: GridPosition { gameState.ballPosition }
    var paintedTiles: Set<GridPosition> { gameState.paintedTiles }
    var moveCount: Int { gameState.moveCount }
    var phase: GamePhase { gameState.phase }

    /// Whether the ball should show the idle pulse
    var shouldPulse: Bool {
        gameState.phase == .awaitingInput && !isAnimatingMovement && !isBumping
    }

    init() {
        let levelData = LevelStore.allLevels[0]
        let state = GameEngine.createInitialState(for: levelData.level)
        self.gameState = state
        self.currentLevelIndex = 0
        self.isShowingCompletion = false
        self.animatingBallPosition = state.ballPosition
        self.bufferedDirection = nil
        self.isBumping = false
        self.bumpDirection = nil
        self.isAnimatingMovement = false
        self.visuallyPaintedTiles = state.paintedTiles
    }

    func handleSwipe(direction: Direction) {
        if gameState.phase == .moving {
            bufferedDirection = direction
            return
        }

        guard gameState.phase == .awaitingInput else { return }

        let result = GameEngine.applyMove(direction: direction, state: &gameState)

        if result.path.isEmpty {
            // Bump animation
            isBumping = true
            bumpDirection = direction
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.isBumping = false
                self?.bumpDirection = nil
            }
            return
        }

        // Cell-by-cell animation
        isAnimatingMovement = true
        animatePath(result.path, stepIndex: 0)
    }

    private func animatePath(_ path: [GridPosition], stepIndex: Int) {
        guard stepIndex < path.count else {
            // Animation complete
            isAnimatingMovement = false
            onAnimationComplete()
            return
        }

        let timePerTile: TimeInterval = 0.125
        let position = path[stepIndex]

        withAnimation(.linear(duration: timePerTile)) {
            animatingBallPosition = position
        }

        // Paint the tile as the ball arrives
        _ = withAnimation(.easeIn(duration: 0.15)) {
            visuallyPaintedTiles.insert(position)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + timePerTile) { [weak self] in
            self?.animatePath(path, stepIndex: stepIndex + 1)
        }
    }

    func onAnimationComplete() {
        let wasWin = gameState.isComplete

        if wasWin {
            gameState.phase = .won
            bufferedDirection = nil
        } else {
            gameState.phase = .awaitingInput
            if let buffered = bufferedDirection {
                bufferedDirection = nil
                handleSwipe(direction: buffered)
            }
        }
    }

    func restart() {
        let levelData = LevelStore.allLevels[currentLevelIndex]
        gameState = GameEngine.createInitialState(for: levelData.level)
        animatingBallPosition = gameState.ballPosition
        bufferedDirection = nil
        isBumping = false
        bumpDirection = nil
        isShowingCompletion = false
        isAnimatingMovement = false
        visuallyPaintedTiles = gameState.paintedTiles
    }

    func advanceLevel() {
        let nextIndex = currentLevelIndex + 1
        if nextIndex < LevelStore.allLevels.count {
            currentLevelIndex = nextIndex
            let levelData = LevelStore.allLevels[nextIndex]
            gameState = GameEngine.createInitialState(for: levelData.level)
            animatingBallPosition = gameState.ballPosition
            bufferedDirection = nil
            isAnimatingMovement = false
            visuallyPaintedTiles = gameState.paintedTiles
        } else {
            isShowingCompletion = true
        }
    }

    func playAgain() {
        isShowingCompletion = false
        currentLevelIndex = 0
        let levelData = LevelStore.allLevels[0]
        gameState = GameEngine.createInitialState(for: levelData.level)
        animatingBallPosition = gameState.ballPosition
        bufferedDirection = nil
        isAnimatingMovement = false
        visuallyPaintedTiles = gameState.paintedTiles
    }
}

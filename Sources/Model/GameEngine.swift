enum GameEngine {
    static func computePath(
        from position: GridPosition,
        direction: Direction,
        grid: [[CellType]],
        rows: Int,
        cols: Int
    ) -> [GridPosition] {
        var path: [GridPosition] = []
        var currentRow = position.row
        var currentCol = position.col

        while true {
            let nextRow = currentRow + direction.rowDelta
            let nextCol = currentCol + direction.colDelta

            guard nextRow >= 0, nextRow < rows, nextCol >= 0, nextCol < cols else {
                break
            }
            guard grid[nextRow][nextCol] != .wall else {
                break
            }

            currentRow = nextRow
            currentCol = nextCol
            path.append(GridPosition(row: currentRow, col: currentCol))
        }

        return path
    }

    @discardableResult
    static func applyMove(
        direction: Direction,
        state: inout GameState
    ) -> MoveResult {
        guard state.phase == .awaitingInput else {
            return MoveResult(path: [], isWin: false, newBallPosition: state.ballPosition)
        }

        let path = computePath(
            from: state.ballPosition,
            direction: direction,
            grid: state.level.grid,
            rows: state.level.rows,
            cols: state.level.cols
        )

        guard !path.isEmpty else {
            return MoveResult(path: [], isWin: false, newBallPosition: state.ballPosition)
        }

        for pos in path {
            state.paintedTiles.insert(pos)
        }
        state.ballPosition = path.last!
        state.moveHistory.append(direction)
        state.moveCount += 1
        state.phase = .moving

        let isWin = state.isComplete
        return MoveResult(path: path, isWin: isWin, newBallPosition: state.ballPosition)
    }

    static func createInitialState(for level: Level) -> GameState {
        GameState(
            level: level,
            ballPosition: level.startPosition,
            paintedTiles: [level.startPosition],
            moveHistory: [],
            phase: .awaitingInput,
            moveCount: 0
        )
    }
}

enum LevelSolver {

    struct Solution {
        let moves: [Direction]
        var moveCount: Int { moves.count }
    }

    private struct SolverState: Hashable {
        let row: UInt8
        let col: UInt8
        let painted: UInt64
    }

    /// Finds the shortest move sequence that paints all floor tiles using BFS.
    /// Returns nil if no solution exists within the state limit.
    static func solve(level: Level, maxStates: Int = 2_000_000) -> Solution? {
        // Map walkable positions to bit indices for compact bitmask representation
        var positionToBit: [GridPosition: Int] = [:]
        for r in 0..<level.rows {
            for c in 0..<level.cols {
                if level.grid[r][c] != .wall {
                    positionToBit[GridPosition(row: r, col: c)] = positionToBit.count
                }
            }
        }

        let totalFloors = positionToBit.count
        guard totalFloors <= 64 else { return nil }
        if totalFloors <= 1 { return Solution(moves: []) }

        let startBit = positionToBit[level.startPosition]!
        let initial = SolverState(
            row: UInt8(level.startPosition.row),
            col: UInt8(level.startPosition.col),
            painted: 1 << startBit
        )

        var visited: Set<SolverState> = [initial]
        // Queue stores (state, packed moves, move count)
        // Packed moves: 2 bits per direction (up=0, down=1, left=2, right=3), max 32 moves
        var queue: [(SolverState, UInt64, Int)] = [(initial, 0, 0)]
        var head = 0

        while head < queue.count {
            if visited.count >= maxStates { break }

            let (current, packedMoves, moveCount) = queue[head]
            head += 1

            // Safety: packed UInt64 supports max 32 moves
            guard moveCount < 32 else { continue }

            let currentPos = GridPosition(row: Int(current.row), col: Int(current.col))

            for dir in Direction.allCases {
                let path = GameEngine.computePath(
                    from: currentPos,
                    direction: dir,
                    grid: level.grid,
                    rows: level.rows,
                    cols: level.cols
                )
                guard !path.isEmpty else { continue }

                var newPainted = current.painted
                for pos in path {
                    if let bit = positionToBit[pos] {
                        newPainted |= (1 << bit)
                    }
                }

                let endPos = path.last!
                let newState = SolverState(
                    row: UInt8(endPos.row),
                    col: UInt8(endPos.col),
                    painted: newPainted
                )

                let dirBits: UInt64
                switch dir {
                case .up: dirBits = 0
                case .down: dirBits = 1
                case .left: dirBits = 2
                case .right: dirBits = 3
                }
                let newPacked = packedMoves | (dirBits << (moveCount * 2))
                let newCount = moveCount + 1

                if newPainted.nonzeroBitCount == totalFloors {
                    return Solution(moves: unpackMoves(newPacked, count: newCount))
                }

                if !visited.contains(newState) {
                    visited.insert(newState)
                    queue.append((newState, newPacked, newCount))
                }
            }
        }

        // BFS exhausted or hit limit: try DFS as fallback
        return solveDFS(level: level, positionToBit: positionToBit, totalFloors: totalFloors)
    }

    /// DFS fallback for larger grids where BFS exceeds memory limits.
    /// Finds a solution (not necessarily optimal) using depth-limited search
    /// with pruning: only explores moves that paint at least one new tile.
    private static func solveDFS(
        level: Level,
        positionToBit: [GridPosition: Int],
        totalFloors: Int,
        maxDepth: Int = 30
    ) -> Solution? {
        let startBit = positionToBit[level.startPosition]!
        let initialPainted: UInt64 = 1 << startBit
        var bestMoves: [Direction]?

        func search(row: Int, col: Int, painted: UInt64, moves: [Direction], depth: Int) {
            if depth > maxDepth { return }
            if let best = bestMoves, moves.count >= best.count { return }

            if painted.nonzeroBitCount == totalFloors {
                bestMoves = moves
                return
            }

            let pos = GridPosition(row: row, col: col)
            for dir in Direction.allCases {
                let path = GameEngine.computePath(
                    from: pos,
                    direction: dir,
                    grid: level.grid,
                    rows: level.rows,
                    cols: level.cols
                )
                guard !path.isEmpty else { continue }

                var newPainted = painted
                var hasNewTile = false
                for p in path {
                    if let bit = positionToBit[p] {
                        if newPainted & (1 << bit) == 0 { hasNewTile = true }
                        newPainted |= (1 << bit)
                    }
                }

                guard hasNewTile else { continue }

                let endPos = path.last!
                search(
                    row: endPos.row,
                    col: endPos.col,
                    painted: newPainted,
                    moves: moves + [dir],
                    depth: depth + 1
                )
            }
        }

        search(
            row: level.startPosition.row,
            col: level.startPosition.col,
            painted: initialPainted,
            moves: [],
            depth: 0
        )

        if let moves = bestMoves {
            return Solution(moves: moves)
        }
        return nil
    }

    private static func unpackMoves(_ packed: UInt64, count: Int) -> [Direction] {
        (0..<count).map { i in
            switch (packed >> (i * 2)) & 0x3 {
            case 0: return .up
            case 1: return .down
            case 2: return .left
            default: return .right
            }
        }
    }

    /// Verifies that a given move sequence paints all floor tiles.
    static func verify(level: Level, moves: [Direction]) -> Bool {
        var state = GameEngine.createInitialState(for: level)
        for move in moves {
            GameEngine.applyMove(direction: move, state: &state)
            state.phase = .awaitingInput
        }
        return state.isComplete
    }
}

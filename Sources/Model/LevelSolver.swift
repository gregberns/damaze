/// BFS-based level solver that finds shortest solutions for ice-sliding puzzles.
/// Uses bitmask state representation for efficient state deduplication.
enum LevelSolver {
    /// Attempts to find the shortest move sequence that paints all floor tiles.
    /// Returns nil if no solution exists within the given constraints.
    static func solve(level: Level, maxMoves: Int = 30, maxStates: Int = 2_000_000) -> [Direction]? {
        // Map each floor/start tile to a bit index for bitmask representation
        var tileIndex: [GridPosition: Int] = [:]
        var idx = 0
        for r in 0..<level.rows {
            for c in 0..<level.cols {
                if level.grid[r][c] != .wall {
                    tileIndex[GridPosition(row: r, col: c)] = idx
                    idx += 1
                }
            }
        }

        let totalTiles = idx
        guard totalTiles > 0, totalTiles <= 64 else { return nil }

        let goalMask: UInt64 = totalTiles == 64 ? UInt64.max : (1 << totalTiles) - 1

        // Precompute all possible moves from each floor position
        var moveTable: [GridPosition: [(Direction, GridPosition, UInt64)]] = [:]
        for (pos, _) in tileIndex {
            var moves: [(Direction, GridPosition, UInt64)] = []
            for dir in Direction.allCases {
                let path = GameEngine.computePath(
                    from: pos,
                    direction: dir,
                    grid: level.grid,
                    rows: level.rows,
                    cols: level.cols
                )
                guard !path.isEmpty else { continue }

                var mask: UInt64 = 0
                for p in path {
                    if let bitIdx = tileIndex[p] {
                        mask |= (1 << bitIdx)
                    }
                }
                moves.append((dir, path.last!, mask))
            }
            moveTable[pos] = moves
        }

        // Initial state
        guard let startBit = tileIndex[level.startPosition] else { return nil }
        let initialPainted: UInt64 = 1 << startBit

        if initialPainted == goalMask { return [] }

        // BFS with parent-pointer tree for path reconstruction
        struct BFSNode {
            let parentIndex: Int
            let direction: Direction
        }

        struct State: Hashable {
            let row: Int16
            let col: Int16
            let painted: UInt64
        }

        let initialState = State(
            row: Int16(level.startPosition.row),
            col: Int16(level.startPosition.col),
            painted: initialPainted
        )

        // Node 0 is sentinel root
        var nodes: [BFSNode] = [BFSNode(parentIndex: -1, direction: .up)]
        var visited: Set<State> = [initialState]
        var queue: [(State, Int, Int)] = [(initialState, 0, 0)] // state, nodeIndex, depth
        var queueIdx = 0

        while queueIdx < queue.count {
            if visited.count > maxStates { break }

            let (current, currentNodeIdx, currentDepth) = queue[queueIdx]
            queueIdx += 1

            if currentDepth >= maxMoves { continue }

            let currentPos = GridPosition(row: Int(current.row), col: Int(current.col))
            guard let moves = moveTable[currentPos] else { continue }

            for (dir, dest, paintMask) in moves {
                let newPainted = current.painted | paintMask
                let newState = State(
                    row: Int16(dest.row),
                    col: Int16(dest.col),
                    painted: newPainted
                )

                guard !visited.contains(newState) else { continue }
                visited.insert(newState)

                let newNodeIdx = nodes.count
                nodes.append(BFSNode(parentIndex: currentNodeIdx, direction: dir))

                if newPainted == goalMask {
                    // Reconstruct solution by walking parent pointers
                    var solution: [Direction] = []
                    var i = newNodeIdx
                    while nodes[i].parentIndex != -1 {
                        solution.append(nodes[i].direction)
                        i = nodes[i].parentIndex
                    }
                    solution.reverse()
                    return solution
                }

                queue.append((newState, newNodeIdx, currentDepth + 1))
            }
        }

        return nil
    }

    /// Computes quality metrics for a solved level.
    static func qualityMetrics(level: Level, solution: [Direction]) -> QualityMetrics {
        let solutionLength = solution.count
        guard solutionLength > 0 else {
            return QualityMetrics(
                solutionLength: 0, forcedMoves: 0,
                backtrackTiles: 0, directionsUsed: 0, score: 0
            )
        }

        var state = GameEngine.createInitialState(for: level)
        var forcedMoves = 0
        var backtrackTiles = 0
        var directionsUsed: Set<Direction> = []

        for move in solution {
            directionsUsed.insert(move)

            let paintedBefore = state.paintedTiles

            // Count how many directions would paint new tiles from current position
            var progressDirections = 0
            for dir in Direction.allCases {
                let testPath = GameEngine.computePath(
                    from: state.ballPosition,
                    direction: dir,
                    grid: level.grid,
                    rows: level.rows,
                    cols: level.cols
                )
                let hasNewTiles = testPath.contains { !state.paintedTiles.contains($0) }
                if hasNewTiles {
                    progressDirections += 1
                }
            }

            if progressDirections <= 1 {
                forcedMoves += 1
            }

            // Execute the move
            state.phase = .awaitingInput
            let result = GameEngine.applyMove(direction: move, state: &state)

            // Count tiles re-traversed (already painted before this move)
            backtrackTiles += result.path.filter { paintedBefore.contains($0) }.count
        }

        let nonForcedRatio = 1.0 - Double(forcedMoves) / Double(solutionLength)
        let directionVariety = Double(directionsUsed.count) / 4.0
        let backtrackRatio = min(Double(backtrackTiles) / Double(level.floorTileCount), 0.5)

        let score = nonForcedRatio * 40.0
            + directionVariety * 20.0
            + backtrackRatio * 20.0
            + Double(solutionLength) * 2.0

        return QualityMetrics(
            solutionLength: solutionLength,
            forcedMoves: forcedMoves,
            backtrackTiles: backtrackTiles,
            directionsUsed: directionsUsed.count,
            score: score
        )
    }

    /// Analyzes how many first-move directions lead to a solvable state.
    /// Tests each of the 4 directions as a first move, then runs the solver
    /// on the resulting state to check if the level is still completable.
    static func analyzeFirstMoves(level: Level, maxMoves: Int = 30) -> FirstMoveAnalysis {
        var solvableDirections: [Direction] = []

        for dir in Direction.allCases {
            let path = GameEngine.computePath(
                from: level.startPosition,
                direction: dir,
                grid: level.grid,
                rows: level.rows,
                cols: level.cols
            )
            guard !path.isEmpty else { continue }

            // Create a modified level state after this first move
            // We need to check if the remaining tiles can still be covered
            var painted: Set<GridPosition> = [level.startPosition]
            for p in path { painted.insert(p) }
            let newPos = path.last!

            if painted.count == level.floorTileCount {
                // First move solves it
                solvableDirections.append(dir)
                continue
            }

            // Build a state and try to solve from here
            let remaining = solveFromState(
                level: level, position: newPos, painted: painted, maxMoves: maxMoves - 1
            )
            if remaining != nil {
                solvableDirections.append(dir)
            }
        }

        return FirstMoveAnalysis(
            totalDirections: 4,
            solvableDirections: solvableDirections.count,
            solvableFrom: solvableDirections
        )
    }

    /// Solves from an arbitrary mid-game state (position + painted set).
    private static func solveFromState(
        level: Level, position: GridPosition,
        painted: Set<GridPosition>, maxMoves: Int
    ) -> [Direction]? {
        var tileIndex: [GridPosition: Int] = [:]
        var idx = 0
        for r in 0..<level.rows {
            for c in 0..<level.cols {
                if level.grid[r][c] != .wall {
                    tileIndex[GridPosition(row: r, col: c)] = idx
                    idx += 1
                }
            }
        }
        let totalTiles = idx
        guard totalTiles > 0, totalTiles <= 64 else { return nil }

        let goalMask: UInt64 = totalTiles == 64 ? UInt64.max : (1 << totalTiles) - 1

        var moveTable: [GridPosition: [(Direction, GridPosition, UInt64)]] = [:]
        for (pos, _) in tileIndex {
            var moves: [(Direction, GridPosition, UInt64)] = []
            for dir in Direction.allCases {
                let path = GameEngine.computePath(
                    from: pos, direction: dir,
                    grid: level.grid, rows: level.rows, cols: level.cols
                )
                guard !path.isEmpty else { continue }
                var mask: UInt64 = 0
                for p in path {
                    if let bitIdx = tileIndex[p] { mask |= (1 << bitIdx) }
                }
                moves.append((dir, path.last!, mask))
            }
            moveTable[pos] = moves
        }

        var initialPainted: UInt64 = 0
        for p in painted {
            if let bitIdx = tileIndex[p] { initialPainted |= (1 << bitIdx) }
        }

        if initialPainted == goalMask { return [] }

        struct State: Hashable {
            let row: Int16; let col: Int16; let painted: UInt64
        }

        let initialState = State(
            row: Int16(position.row), col: Int16(position.col), painted: initialPainted
        )
        var visited: Set<State> = [initialState]
        var queue: [(State, Int)] = [(initialState, 0)]
        var queueIdx = 0

        while queueIdx < queue.count {
            if visited.count > 500_000 { break }
            let (current, depth) = queue[queueIdx]
            queueIdx += 1
            if depth >= maxMoves { continue }

            let currentPos = GridPosition(row: Int(current.row), col: Int(current.col))
            guard let moves = moveTable[currentPos] else { continue }

            for (_, dest, paintMask) in moves {
                let newPainted = current.painted | paintMask
                let newState = State(row: Int16(dest.row), col: Int16(dest.col), painted: newPainted)
                guard !visited.contains(newState) else { continue }
                visited.insert(newState)
                if newPainted == goalMask { return [] } // solvable
                queue.append((newState, depth + 1))
            }
        }
        return nil
    }
}

struct FirstMoveAnalysis {
    let totalDirections: Int
    let solvableDirections: Int
    let solvableFrom: [Direction]
}

struct QualityMetrics {
    let solutionLength: Int
    let forcedMoves: Int
    let backtrackTiles: Int
    let directionsUsed: Int
    let score: Double
}

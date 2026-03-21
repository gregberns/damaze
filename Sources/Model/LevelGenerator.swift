import Foundation

/// Procedural level generator that creates solvable ice-sliding puzzles.
/// Uses generate-and-test: creates random grids, validates solvability via LevelSolver,
/// and scores quality to select the best candidates.
enum LevelGenerator {
    struct Config {
        let rows: Int
        let cols: Int
        let wallDensity: Double
        let minSolutionLength: Int
        let maxSolutionLength: Int
        /// Minimum number of first-move directions that must lead to a solvable state.
        /// Set to 2+ to avoid "wrong first move = stuck" levels. Default 2.
        let minFirstMoveDirections: Int

        init(rows: Int, cols: Int, wallDensity: Double,
             minSolutionLength: Int, maxSolutionLength: Int,
             minFirstMoveDirections: Int = 2) {
            self.rows = rows
            self.cols = cols
            self.wallDensity = wallDensity
            self.minSolutionLength = minSolutionLength
            self.maxSolutionLength = maxSolutionLength
            self.minFirstMoveDirections = minFirstMoveDirections
        }
    }

    struct GeneratedLevel {
        let grid: [[Int]]
        let solution: [Direction]
        let quality: QualityMetrics
    }

    /// Generates the best solvable level matching the config constraints.
    /// Returns nil if no valid level found within maxAttempts.
    static func generate(config: Config, maxAttempts: Int = 5000) -> GeneratedLevel? {
        var bestResult: GeneratedLevel?
        var bestScore: Double = -.infinity

        for _ in 0..<maxAttempts {
            guard let (grid, level) = randomGrid(
                rows: config.rows,
                cols: config.cols,
                wallDensity: config.wallDensity
            ) else { continue }

            guard let solution = LevelSolver.solve(
                level: level,
                maxMoves: config.maxSolutionLength
            ) else { continue }

            if solution.count < config.minSolutionLength { continue }

            // Check first-move flexibility
            if config.minFirstMoveDirections > 1 {
                let analysis = LevelSolver.analyzeFirstMoves(level: level, maxMoves: config.maxSolutionLength)
                if analysis.solvableDirections < config.minFirstMoveDirections { continue }
            }

            let quality = LevelSolver.qualityMetrics(level: level, solution: solution)

            if quality.score > bestScore {
                bestScore = quality.score
                bestResult = GeneratedLevel(grid: grid, solution: solution, quality: quality)
            }
        }

        return bestResult
    }

    /// Generates multiple distinct levels matching the config.
    static func generateBatch(config: Config, count: Int, maxAttemptsPerLevel: Int = 3000) -> [GeneratedLevel] {
        var results: [GeneratedLevel] = []
        let totalAttempts = count * maxAttemptsPerLevel

        for _ in 0..<totalAttempts {
            if results.count >= count { break }

            guard let (grid, level) = randomGrid(
                rows: config.rows,
                cols: config.cols,
                wallDensity: config.wallDensity
            ) else { continue }

            guard let solution = LevelSolver.solve(
                level: level,
                maxMoves: config.maxSolutionLength
            ) else { continue }

            if solution.count < config.minSolutionLength { continue }

            if config.minFirstMoveDirections > 1 {
                let analysis = LevelSolver.analyzeFirstMoves(level: level, maxMoves: config.maxSolutionLength)
                if analysis.solvableDirections < config.minFirstMoveDirections { continue }
            }

            let quality = LevelSolver.qualityMetrics(level: level, solution: solution)
            results.append(GeneratedLevel(grid: grid, solution: solution, quality: quality))
        }

        return results.sorted { $0.quality.score > $1.quality.score }
    }

    // MARK: - Grid Generation

    /// Creates a random grid with the given wall density, ensuring connectivity.
    /// Returns the raw int grid and the validated Level, or nil if generation fails.
    static func randomGrid(rows: Int, cols: Int, wallDensity: Double) -> ([[Int]], Level)? {
        var grid = Array(repeating: Array(repeating: 0, count: cols), count: rows)

        // Randomly assign floor tiles based on wall density
        for r in 0..<rows {
            for c in 0..<cols {
                if Double.random(in: 0..<1) >= wallDensity {
                    grid[r][c] = 1
                }
            }
        }

        // Find largest connected component via BFS
        var visited = Array(repeating: Array(repeating: false, count: cols), count: rows)
        var bestComponent: [GridPosition] = []

        for r in 0..<rows {
            for c in 0..<cols {
                if grid[r][c] != 0 && !visited[r][c] {
                    var component: [GridPosition] = []
                    var bfsQueue: [GridPosition] = [GridPosition(row: r, col: c)]
                    visited[r][c] = true

                    while !bfsQueue.isEmpty {
                        let pos = bfsQueue.removeFirst()
                        component.append(pos)

                        for (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)] {
                            let nr = pos.row + dr
                            let nc = pos.col + dc
                            if nr >= 0 && nr < rows && nc >= 0 && nc < cols
                                && grid[nr][nc] != 0 && !visited[nr][nc] {
                                visited[nr][nc] = true
                                bfsQueue.append(GridPosition(row: nr, col: nc))
                            }
                        }
                    }

                    if component.count > bestComponent.count {
                        bestComponent = component
                    }
                }
            }
        }

        // Require minimum floor tiles for an interesting puzzle (scales with grid size)
        let minFloorTiles = max(8, (rows * cols) / 6)
        guard bestComponent.count >= minFloorTiles else { return nil }

        // Remove tiles not in the largest connected component
        let componentSet = Set(bestComponent)
        for r in 0..<rows {
            for c in 0..<cols {
                if grid[r][c] != 0 && !componentSet.contains(GridPosition(row: r, col: c)) {
                    grid[r][c] = 0
                }
            }
        }

        // Place start at a random floor tile
        guard let startPos = bestComponent.randomElement() else { return nil }
        grid[startPos.row][startPos.col] = 2

        guard let level = try? Level(grid: grid) else { return nil }
        return (grid, level)
    }
}

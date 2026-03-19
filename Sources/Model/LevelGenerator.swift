struct LevelMetrics {
    let solutionLength: Int
    let floorTileCount: Int
    let gridRows: Int
    let gridCols: Int
    let wallCount: Int
}

struct GeneratedLevel {
    let grid: [[Int]]
    let solution: [Direction]
    let metrics: LevelMetrics
}

enum LevelGenerator {

    struct Config {
        let rows: Int
        let cols: Int
        let minWalls: Int
        let maxWalls: Int
        let targetSolutionRange: ClosedRange<Int>
    }

    static let easyConfig = Config(
        rows: 4, cols: 4, minWalls: 2, maxWalls: 6,
        targetSolutionRange: 3...6
    )
    static let mediumSmallConfig = Config(
        rows: 5, cols: 5, minWalls: 4, maxWalls: 10,
        targetSolutionRange: 5...10
    )
    static let mediumConfig = Config(
        rows: 5, cols: 6, minWalls: 6, maxWalls: 14,
        targetSolutionRange: 7...14
    )
    static let hardConfig = Config(
        rows: 6, cols: 6, minWalls: 8, maxWalls: 18,
        targetSolutionRange: 8...20
    )
    static let hardLargeConfig = Config(
        rows: 7, cols: 7, minWalls: 12, maxWalls: 24,
        targetSolutionRange: 10...25
    )

    /// Generates candidate solvable levels matching the configuration.
    /// Returns levels sorted by solution length (longest first).
    static func generate(config: Config, attempts: Int = 500) -> [GeneratedLevel] {
        var results: [GeneratedLevel] = []

        for _ in 0..<attempts {
            guard let candidate = generateCandidate(config: config) else { continue }
            results.append(candidate)
        }

        results.sort { $0.metrics.solutionLength > $1.metrics.solutionLength }
        return results
    }

    private static func generateCandidate(config: Config) -> GeneratedLevel? {
        var grid = Array(repeating: Array(repeating: 1, count: config.cols), count: config.rows)

        // Place start on an edge
        let edge = Int.random(in: 0...3)
        let startRow: Int
        let startCol: Int
        switch edge {
        case 0: startRow = 0; startCol = Int.random(in: 0..<config.cols)
        case 1: startRow = config.rows - 1; startCol = Int.random(in: 0..<config.cols)
        case 2: startRow = Int.random(in: 0..<config.rows); startCol = 0
        default: startRow = Int.random(in: 0..<config.rows); startCol = config.cols - 1
        }
        grid[startRow][startCol] = 2

        // Place random walls
        let wallCount = Int.random(in: config.minWalls...config.maxWalls)
        var placed = 0
        var wallAttempts = 0
        while placed < wallCount && wallAttempts < wallCount * 20 {
            wallAttempts += 1
            let r = Int.random(in: 0..<config.rows)
            let c = Int.random(in: 0..<config.cols)
            if grid[r][c] == 1 {
                grid[r][c] = 0
                placed += 1
            }
        }

        // Validate
        guard let level = try? Level(grid: grid) else { return nil }

        // Solve (lower state limit for speed during generation)
        guard let solution = LevelSolver.solve(level: level, maxStates: 500_000) else { return nil }

        // Filter by target solution length
        guard config.targetSolutionRange.contains(solution.moveCount) else { return nil }

        let totalCells = config.rows * config.cols
        let metrics = LevelMetrics(
            solutionLength: solution.moveCount,
            floorTileCount: level.floorTileCount,
            gridRows: config.rows,
            gridCols: config.cols,
            wallCount: totalCells - level.floorTileCount
        )

        return GeneratedLevel(grid: grid, solution: solution.moves, metrics: metrics)
    }
}

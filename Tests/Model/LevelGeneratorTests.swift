import XCTest
@testable import Damaze

final class LevelGeneratorTests: XCTestCase {

    func test_generate_easyLevel_findsSolvableLevel() {
        let config = LevelGenerator.Config(
            rows: 4, cols: 4,
            wallDensity: 0.2,
            minSolutionLength: 3,
            maxSolutionLength: 6
        )
        let result = LevelGenerator.generate(config: config, maxAttempts: 2000)
        XCTAssertNotNil(result, "Should generate at least one easy level")

        if let result = result {
            XCTAssertGreaterThanOrEqual(result.solution.count, 3)
            XCTAssertLessThanOrEqual(result.solution.count, 6)
        }
    }

    func test_generate_mediumLevel_findsSolvableLevel() {
        let config = LevelGenerator.Config(
            rows: 5, cols: 5,
            wallDensity: 0.25,
            minSolutionLength: 5,
            maxSolutionLength: 10
        )
        let result = LevelGenerator.generate(config: config, maxAttempts: 3000)
        XCTAssertNotNil(result, "Should generate at least one medium level")

        if let result = result {
            XCTAssertGreaterThanOrEqual(result.solution.count, 5)
            XCTAssertLessThanOrEqual(result.solution.count, 10)
        }
    }

    func test_generate_hardLevel_findsSolvableLevel() {
        let config = LevelGenerator.Config(
            rows: 6, cols: 6,
            wallDensity: 0.3,
            minSolutionLength: 7,
            maxSolutionLength: 15
        )
        let result = LevelGenerator.generate(config: config, maxAttempts: 5000)
        XCTAssertNotNil(result, "Should generate at least one hard level")

        if let result = result {
            XCTAssertGreaterThanOrEqual(result.solution.count, 7)
            XCTAssertLessThanOrEqual(result.solution.count, 15)
        }
    }

    func test_generate_generatedLevelPassesSolverVerification() {
        let config = LevelGenerator.Config(
            rows: 5, cols: 5,
            wallDensity: 0.25,
            minSolutionLength: 4,
            maxSolutionLength: 8
        )
        guard let result = LevelGenerator.generate(config: config) else {
            XCTFail("Should generate a level")
            return
        }

        // Verify the generated solution actually works
        let level = try! Level(grid: result.grid)
        var state = GameEngine.createInitialState(for: level)
        for move in result.solution {
            state.phase = .awaitingInput
            GameEngine.applyMove(direction: move, state: &state)
        }
        XCTAssertTrue(state.isComplete, "Generated solution should complete the level")
    }

    func test_randomGrid_producesValidLevel() {
        var found = false
        for _ in 0..<100 {
            if let (grid, level) = LevelGenerator.randomGrid(rows: 5, cols: 5, wallDensity: 0.25) {
                XCTAssertEqual(grid.count, 5)
                XCTAssertEqual(grid[0].count, 5)
                XCTAssertGreaterThanOrEqual(level.floorTileCount, 8)
                found = true
                break
            }
        }
        XCTAssertTrue(found, "Should produce at least one valid grid in 100 attempts")
    }

    func test_generateBatch_producesMultipleLevels() {
        let config = LevelGenerator.Config(
            rows: 4, cols: 4,
            wallDensity: 0.15,
            minSolutionLength: 3,
            maxSolutionLength: 6
        )
        let levels = LevelGenerator.generateBatch(config: config, count: 3)
        XCTAssertGreaterThanOrEqual(levels.count, 1, "Should generate at least 1 level")
    }

    func test_randomGrid_respectsFloorTileLimit() {
        // Large grid with low wall density might exceed 64 floor tiles
        // Generator should reject these
        var allUnder64 = true
        for _ in 0..<50 {
            if let (_, level) = LevelGenerator.randomGrid(rows: 10, cols: 10, wallDensity: 0.2) {
                if level.floorTileCount > 64 {
                    allUnder64 = false
                    break
                }
            }
        }
        XCTAssertTrue(allUnder64, "Generator should not produce grids with >64 floor tiles")
    }

    // MARK: - Audit & Generation Output

    func test_audit_allLevels_firstMoveFlexibility() {
        for (i, levelData) in LevelStore.allLevels.enumerated() {
            let level = levelData.level
            let viable = LevelSolver.viableFirstMoves(level: level)
            let valid = LevelSolver.validFirstMoves(level: level)
            let solution = LevelSolver.solve(level: level)
            let quality = solution.map { LevelSolver.qualityMetrics(level: level, solution: $0) }

            print("AUDIT Level \(i+1) (\(levelData.name)): " +
                  "viable=\(viable.count)/\(valid.count) first moves, " +
                  "solution=\(solution?.count ?? -1) moves, " +
                  "score=\(String(format: "%.1f", quality?.score ?? 0)), " +
                  "viable_dirs=\(viable), " +
                  "forced=\(quality?.forcedMoves ?? 0)")
        }
    }

    func test_printCandidateLevels() {
        let tiers: [(name: String, config: LevelGenerator.Config)] = [
            ("MEDIUM 6x6", LevelGenerator.Config(rows: 6, cols: 6, wallDensity: 0.30, minSolutionLength: 8, maxSolutionLength: 14)),
            ("MEDIUM 7x7", LevelGenerator.Config(rows: 7, cols: 7, wallDensity: 0.35, minSolutionLength: 8, maxSolutionLength: 14)),
            ("MEDIUM 8x7", LevelGenerator.Config(rows: 8, cols: 7, wallDensity: 0.40, minSolutionLength: 8, maxSolutionLength: 14)),
            ("MEDIUM 9x8", LevelGenerator.Config(rows: 9, cols: 8, wallDensity: 0.45, minSolutionLength: 8, maxSolutionLength: 14)),
            ("HARD 8x8", LevelGenerator.Config(rows: 8, cols: 8, wallDensity: 0.45, minSolutionLength: 15, maxSolutionLength: 25)),
            ("HARD 9x9", LevelGenerator.Config(rows: 9, cols: 9, wallDensity: 0.50, minSolutionLength: 15, maxSolutionLength: 25)),
            ("HARD 10x10", LevelGenerator.Config(rows: 10, cols: 10, wallDensity: 0.55, minSolutionLength: 15, maxSolutionLength: 25)),
            ("HARD 12x10", LevelGenerator.Config(rows: 12, cols: 10, wallDensity: 0.60, minSolutionLength: 15, maxSolutionLength: 25)),
        ]

        for (tierName, config) in tiers {
            print("\n// === \(tierName) ===")
            let levels = LevelGenerator.generateBatch(config: config, count: 3, maxAttemptsPerLevel: 5000)
            for (i, level) in levels.prefix(2).enumerated() {
                let dirs = level.solution.map { dir -> String in
                    switch dir {
                    case .up: return ".up"
                    case .down: return ".down"
                    case .left: return ".left"
                    case .right: return ".right"
                    }
                }.joined(separator: ", ")
                print("// \(tierName) #\(i+1): \(level.solution.count) moves, score=\(String(format: "%.1f", level.quality.score)), viable=\(level.quality.viableFirstMoves), forced=\(level.quality.forcedMoves)")
                print("// Solution: [\(dirs)]")
                print("// Grid:")
                for row in level.grid {
                    print("//   \(row),")
                }
            }
            if levels.isEmpty {
                print("// NO LEVELS GENERATED for \(tierName)")
            }
        }
    }
}

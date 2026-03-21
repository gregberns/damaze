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

    // MARK: - Level Generation Output (for curating LevelStore)

    func test_printCandidateLevels() {
        let tiers: [(name: String, config: LevelGenerator.Config)] = [
            // Replacements for bad medium levels (8, 9, 10)
            ("MEDIUM-REPLACE 5x5", LevelGenerator.Config(rows: 5, cols: 5, wallDensity: 0.25, minSolutionLength: 8, maxSolutionLength: 12)),
            ("MEDIUM-REPLACE 6x5", LevelGenerator.Config(rows: 6, cols: 5, wallDensity: 0.3, minSolutionLength: 8, maxSolutionLength: 12)),
            // New medium levels (6x6 to 9x9, 8-14 moves)
            ("MEDIUM 6x6", LevelGenerator.Config(rows: 6, cols: 6, wallDensity: 0.3, minSolutionLength: 8, maxSolutionLength: 14)),
            ("MEDIUM 7x6", LevelGenerator.Config(rows: 7, cols: 6, wallDensity: 0.35, minSolutionLength: 8, maxSolutionLength: 14)),
            ("MEDIUM 7x7", LevelGenerator.Config(rows: 7, cols: 7, wallDensity: 0.35, minSolutionLength: 8, maxSolutionLength: 14)),
            ("MEDIUM 8x7", LevelGenerator.Config(rows: 8, cols: 7, wallDensity: 0.4, minSolutionLength: 8, maxSolutionLength: 14)),
            ("MEDIUM 8x8", LevelGenerator.Config(rows: 8, cols: 8, wallDensity: 0.4, minSolutionLength: 8, maxSolutionLength: 14)),
            ("MEDIUM 9x9", LevelGenerator.Config(rows: 9, cols: 9, wallDensity: 0.45, minSolutionLength: 8, maxSolutionLength: 14)),
            // Replacement for level 12
            ("MEDIUM-HARD 7x7", LevelGenerator.Config(rows: 7, cols: 7, wallDensity: 0.35, minSolutionLength: 10, maxSolutionLength: 16)),
            // New hard levels (8x8 to 12x12, 15-25+ moves)
            ("HARD 8x8", LevelGenerator.Config(rows: 8, cols: 8, wallDensity: 0.4, minSolutionLength: 14, maxSolutionLength: 25)),
            ("HARD 9x9", LevelGenerator.Config(rows: 9, cols: 9, wallDensity: 0.45, minSolutionLength: 14, maxSolutionLength: 25)),
            ("HARD 10x10", LevelGenerator.Config(rows: 10, cols: 10, wallDensity: 0.5, minSolutionLength: 15, maxSolutionLength: 25)),
            ("HARD 11x11", LevelGenerator.Config(rows: 11, cols: 11, wallDensity: 0.55, minSolutionLength: 15, maxSolutionLength: 25)),
            ("HARD 12x12", LevelGenerator.Config(rows: 12, cols: 12, wallDensity: 0.6, minSolutionLength: 15, maxSolutionLength: 25)),
        ]

        for (tierName, config) in tiers {
            print("\n// === \(tierName) ===")
            let levels = LevelGenerator.generateBatch(config: config, count: 5, maxAttemptsPerLevel: 5000)
            if levels.isEmpty {
                print("// NO LEVELS GENERATED")
                continue
            }
            for (i, level) in levels.prefix(3).enumerated() {
                let dirs = level.solution.map { dir -> String in
                    switch dir {
                    case .up: return ".up"
                    case .down: return ".down"
                    case .left: return ".left"
                    case .right: return ".right"
                    }
                }.joined(separator: ", ")
                print("// \(tierName) #\(i+1): \(level.solution.count) moves, score=\(String(format: "%.1f", level.quality.score)), forced=\(level.quality.forcedMoves), firstMoveRatio=\(String(format: "%.0f%%", level.quality.firstMoveSolvableRatio * 100))")
                print("// Solution: [\(dirs)]")
                for row in level.grid {
                    print("//   \(row),")
                }
            }
        }
    }
}

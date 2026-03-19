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
    // Run this test to see candidate levels printed to console

    func test_printCandidateLevels() {
        let tiers: [(name: String, config: LevelGenerator.Config)] = [
            ("EASY 4x4", LevelGenerator.Config(rows: 4, cols: 4, wallDensity: 0.15, minSolutionLength: 3, maxSolutionLength: 6)),
            ("EASY 5x4", LevelGenerator.Config(rows: 5, cols: 4, wallDensity: 0.2, minSolutionLength: 4, maxSolutionLength: 7)),
            ("MEDIUM 5x5", LevelGenerator.Config(rows: 5, cols: 5, wallDensity: 0.25, minSolutionLength: 5, maxSolutionLength: 10)),
            ("MEDIUM 6x5", LevelGenerator.Config(rows: 6, cols: 5, wallDensity: 0.3, minSolutionLength: 6, maxSolutionLength: 12)),
            ("HARD 6x6", LevelGenerator.Config(rows: 6, cols: 6, wallDensity: 0.3, minSolutionLength: 7, maxSolutionLength: 15)),
            ("HARD 7x7", LevelGenerator.Config(rows: 7, cols: 7, wallDensity: 0.35, minSolutionLength: 8, maxSolutionLength: 20)),
        ]

        for (tierName, config) in tiers {
            print("\n// === \(tierName) ===")
            let levels = LevelGenerator.generateBatch(config: config, count: 5, maxAttemptsPerLevel: 3000)
            for (i, level) in levels.prefix(3).enumerated() {
                let dirs = level.solution.map { dir -> String in
                    switch dir {
                    case .up: return ".up"
                    case .down: return ".down"
                    case .left: return ".left"
                    case .right: return ".right"
                    }
                }.joined(separator: ", ")
                print("// \(tierName) #\(i+1): \(level.solution.count) moves, score=\(String(format: "%.1f", level.quality.score)), forced=\(level.quality.forcedMoves)")
                print("// Solution: [\(dirs)]")
                for row in level.grid {
                    print("//   \(row),")
                }
            }
        }
    }
}

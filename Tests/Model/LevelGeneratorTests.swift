import XCTest
@testable import Damaze

final class LevelGeneratorTests: XCTestCase {

    func test_generate_easyConfig_producesSolvableLevels() {
        let results = LevelGenerator.generate(config: LevelGenerator.easyConfig, attempts: 100)
        XCTAssertFalse(results.isEmpty, "Should produce at least some solvable easy levels")
        for generated in results {
            let level = try! Level(grid: generated.grid)
            XCTAssertTrue(
                LevelSolver.verify(level: level, moves: generated.solution),
                "Generated level should be solvable with its solution"
            )
            XCTAssertTrue(
                LevelGenerator.easyConfig.targetSolutionRange.contains(generated.metrics.solutionLength),
                "Solution length \(generated.metrics.solutionLength) should be in target range"
            )
        }
    }

    func test_generate_mediumSmallConfig_producesSolvableLevels() {
        let results = LevelGenerator.generate(config: LevelGenerator.mediumSmallConfig, attempts: 100)
        for generated in results {
            let level = try! Level(grid: generated.grid)
            XCTAssertTrue(LevelSolver.verify(level: level, moves: generated.solution))
        }
    }

    func test_generate_metricsAreAccurate() {
        let results = LevelGenerator.generate(config: LevelGenerator.easyConfig, attempts: 50)
        for generated in results {
            let level = try! Level(grid: generated.grid)
            XCTAssertEqual(generated.metrics.floorTileCount, level.floorTileCount)
            XCTAssertEqual(generated.metrics.gridRows, level.rows)
            XCTAssertEqual(generated.metrics.gridCols, level.cols)
            XCTAssertEqual(generated.metrics.solutionLength, generated.solution.count)
        }
    }
}

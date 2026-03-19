import XCTest
@testable import Damaze

final class LevelSolverTests: XCTestCase {

    // MARK: - Solver Tests on Existing Levels

    func test_solve_level1_findsOptimalSolution() {
        let level = LevelStore.level1.level
        let solution = LevelSolver.solve(level: level)
        XCTAssertNotNil(solution)
        XCTAssertEqual(solution?.moveCount, 4)
        XCTAssertTrue(LevelSolver.verify(level: level, moves: solution!.moves))
    }

    func test_solve_level2_findsOptimalSolution() {
        let level = LevelStore.level2.level
        let solution = LevelSolver.solve(level: level)
        XCTAssertNotNil(solution)
        XCTAssertEqual(solution?.moveCount, 6)
        XCTAssertTrue(LevelSolver.verify(level: level, moves: solution!.moves))
    }

    func test_solve_level3_findsSolution() {
        let level = LevelStore.level3.level
        let solution = LevelSolver.solve(level: level)
        XCTAssertNotNil(solution)
        XCTAssertTrue(LevelSolver.verify(level: level, moves: solution!.moves))
    }

    // MARK: - Edge Cases

    func test_solve_trivialOneMove_returnsOneMovesSolution() throws {
        let level = try Level(grid: [[2, 1]])
        let solution = LevelSolver.solve(level: level)
        XCTAssertNotNil(solution)
        XCTAssertEqual(solution?.moveCount, 1)
        XCTAssertEqual(solution?.moves, [.right])
    }

    func test_solve_singleTile_returnsEmptySolution() throws {
        let level = try Level(grid: [
            [0, 0, 0],
            [0, 2, 0],
            [0, 0, 0],
        ])
        let solution = LevelSolver.solve(level: level)
        XCTAssertNotNil(solution)
        XCTAssertEqual(solution?.moveCount, 0)
    }

    func test_solve_unsolvable_returnsNil() throws {
        // Ball at center surrounded by walls, but floor tiles in corners are unreachable
        let level = try Level(grid: [
            [1, 0, 1],
            [0, 2, 0],
            [1, 0, 1],
        ])
        let solution = LevelSolver.solve(level: level)
        XCTAssertNil(solution)
    }

    // MARK: - Verify Tests

    func test_verify_correctSolution_returnsTrue() {
        let level = LevelStore.level1.level
        XCTAssertTrue(LevelSolver.verify(level: level, moves: [.left, .up, .right, .down]))
    }

    func test_verify_incompleteSolution_returnsFalse() {
        let level = LevelStore.level1.level
        XCTAssertFalse(LevelSolver.verify(level: level, moves: [.left, .up]))
    }

    func test_verify_emptyMoves_returnsFalse() {
        let level = LevelStore.level1.level
        XCTAssertFalse(LevelSolver.verify(level: level, moves: []))
    }

    // MARK: - All Shipped Levels Have Valid Solutions

    func test_allLevels_areSolvable() {
        for (index, levelData) in LevelStore.allLevels.enumerated() {
            let solution = LevelSolver.solve(level: levelData.level)
            XCTAssertNotNil(solution, "Level \(index + 1) (\(levelData.name)) should be solvable")
        }
    }
}

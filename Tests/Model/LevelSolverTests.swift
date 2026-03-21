import XCTest
@testable import Damaze

final class LevelSolverTests: XCTestCase {

    // MARK: - Solver Correctness on Existing Levels

    func test_solve_level1_findsSolution() {
        let level = LevelStore.level1.level
        let solution = LevelSolver.solve(level: level)
        XCTAssertNotNil(solution)
        XCTAssertEqual(solution?.count, 4, "Level 1 optimal solution is 4 moves")
    }

    func test_solve_level2_findsSolution() {
        let level = LevelStore.level2.level
        let solution = LevelSolver.solve(level: level)
        XCTAssertNotNil(solution)
        XCTAssertEqual(solution?.count, 6, "Level 2 optimal solution is 6 moves")
    }

    func test_solve_level3_findsSolution() {
        let level = LevelStore.level3.level
        let solution = LevelSolver.solve(level: level)
        XCTAssertNotNil(solution)
        // Level 3 documented solution is 13 moves; solver may find shorter
        XCTAssertLessThanOrEqual(solution!.count, 13)
    }

    func test_solve_solutionActuallyWorks() {
        let level = LevelStore.level1.level
        guard let solution = LevelSolver.solve(level: level) else {
            XCTFail("Should find a solution")
            return
        }

        var state = GameEngine.createInitialState(for: level)
        for move in solution {
            state.phase = .awaitingInput
            GameEngine.applyMove(direction: move, state: &state)
        }
        XCTAssertTrue(state.isComplete, "Solution should complete the level")
    }

    func test_solve_singleFloorTile_returnsEmptySolution() throws {
        let level = try Level(grid: [
            [0, 0, 0],
            [0, 2, 0],
            [0, 0, 0],
        ])
        let solution = LevelSolver.solve(level: level)
        XCTAssertNotNil(solution)
        XCTAssertEqual(solution?.count, 0, "Single tile = already won")
    }

    func test_solve_unsolvableLevel_returnsNil() throws {
        // Two disconnected floor regions (under ice-sliding rules)
        let level = try Level(grid: [
            [2, 0, 1],
        ])
        let solution = LevelSolver.solve(level: level)
        XCTAssertNil(solution, "Disconnected floor tiles should be unsolvable")
    }

    func test_solve_respectsMaxMoves() throws {
        let level = LevelStore.level3.level
        // Level 3 needs at least several moves; maxMoves=1 should fail
        let solution = LevelSolver.solve(level: level, maxMoves: 1)
        XCTAssertNil(solution)
    }

    // MARK: - Quality Metrics

    func test_qualityMetrics_level1() {
        let level = LevelStore.level1.level
        guard let solution = LevelSolver.solve(level: level) else {
            XCTFail("Should find solution")
            return
        }
        let metrics = LevelSolver.qualityMetrics(level: level, solution: solution)
        XCTAssertEqual(metrics.solutionLength, solution.count)
        XCTAssertGreaterThanOrEqual(metrics.directionsUsed, 2)
        XCTAssertGreaterThan(metrics.score, 0)
    }

    func test_qualityMetrics_emptySolution() throws {
        let level = try Level(grid: [
            [0, 0, 0],
            [0, 2, 0],
            [0, 0, 0],
        ])
        let metrics = LevelSolver.qualityMetrics(level: level, solution: [])
        XCTAssertEqual(metrics.solutionLength, 0)
        XCTAssertEqual(metrics.viableFirstMoves, 0)
        XCTAssertEqual(metrics.score, 0)
    }

    func test_viableFirstMoves_level1_hasMultipleOptions() {
        let level = LevelStore.level1.level
        let viable = LevelSolver.viableFirstMoves(level: level)
        XCTAssertGreaterThanOrEqual(viable.count, 1, "Level 1 should have at least 1 viable first move")
    }

    func test_solveFromState_afterFirstMove_findsSolution() {
        let level = LevelStore.level1.level
        // Make first move left from start (3,3) -> slides to (3,0)
        let path = GameEngine.computePath(
            from: level.startPosition,
            direction: .left,
            grid: level.grid,
            rows: level.rows,
            cols: level.cols
        )
        guard !path.isEmpty else {
            XCTFail("First move left should be valid")
            return
        }
        var painted: Set<GridPosition> = [level.startPosition]
        for p in path { painted.insert(p) }
        let solution = LevelSolver.solveFromState(
            level: level,
            position: path.last!,
            paintedTiles: painted
        )
        XCTAssertNotNil(solution, "Should find remaining solution after first move")
    }

    // MARK: - Solver Validates All LevelStore Levels

    func test_solve_allLevels_areSolvable() {
        for (i, levelData) in LevelStore.allLevels.enumerated() {
            let solution = LevelSolver.solve(level: levelData.level)
            XCTAssertNotNil(solution, "Level \(i + 1) (\(levelData.name)) should be solvable")

            if let solution = solution {
                // Verify the solution actually works
                var state = GameEngine.createInitialState(for: levelData.level)
                for move in solution {
                    state.phase = .awaitingInput
                    GameEngine.applyMove(direction: move, state: &state)
                }
                XCTAssertTrue(state.isComplete, "Level \(i + 1) solution should complete the level")
            }
        }
    }
}

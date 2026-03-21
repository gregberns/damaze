import XCTest
@testable import Damaze

final class LevelAuditTests: XCTestCase {

    /// Audit all levels for first-move dependency and area isolation.
    func test_auditAllLevels_firstMoveDependency() {
        for (i, levelData) in LevelStore.allLevels.enumerated() {
            let level = levelData.level
            let levelNum = i + 1

            guard let optimalSolution = LevelSolver.solve(level: level) else {
                print("FAIL Level \(levelNum) (\(levelData.name)): NO SOLUTION FOUND")
                XCTFail("Level \(levelNum) has no solution")
                continue
            }

            var solvableFirstMoves: [Direction] = []
            var unsolvableFirstMoves: [Direction] = []
            var invalidFirstMoves: [Direction] = []

            for dir in Direction.allCases {
                let path = GameEngine.computePath(
                    from: level.startPosition,
                    direction: dir,
                    grid: level.grid,
                    rows: level.rows,
                    cols: level.cols
                )

                if path.isEmpty {
                    invalidFirstMoves.append(dir)
                    continue
                }

                var paintedAfterFirst: Set<GridPosition> = [level.startPosition]
                for p in path {
                    paintedAfterFirst.insert(p)
                }

                if LevelSolver.solveFromState(
                    level: level,
                    position: path.last!,
                    paintedTiles: paintedAfterFirst,
                    maxMoves: 30
                ) != nil {
                    solvableFirstMoves.append(dir)
                } else {
                    unsolvableFirstMoves.append(dir)
                }
            }

            let validFirstMoves = solvableFirstMoves.count + unsolvableFirstMoves.count
            let solvableRatio = validFirstMoves > 0
                ? Double(solvableFirstMoves.count) / Double(validFirstMoves)
                : 0.0

            let quality = LevelSolver.qualityMetrics(level: level, solution: optimalSolution)

            let flag: String
            if solvableFirstMoves.count <= 1 && validFirstMoves >= 2 {
                flag = "CRITICAL"
            } else if solvableRatio < 0.5 {
                flag = "WARNING"
            } else {
                flag = "OK"
            }

            // Print solution for test generation
            let dirs = optimalSolution.map { dir -> String in
                switch dir {
                case .up: return ".up"
                case .down: return ".down"
                case .left: return ".left"
                case .right: return ".right"
                }
            }.joined(separator: ", ")

            print("""
            Level \(levelNum) (\(levelData.name)) \(level.rows)x\(level.cols) — \(flag)
              Solution (\(optimalSolution.count) moves): [\(dirs)]
              Score=\(String(format: "%.1f", quality.score)), forced=\(quality.forcedMoves), firstMoveRatio=\(String(format: "%.0f%%", quality.firstMoveSolvableRatio * 100))
              Solvable first moves: \(solvableFirstMoves.count)/\(validFirstMoves) \(solvableFirstMoves)
            """)

            // Assert no CRITICAL levels in the store
            if validFirstMoves >= 2 {
                XCTAssertGreaterThan(
                    solvableFirstMoves.count, 1,
                    "Level \(levelNum) (\(levelData.name)) has critical first-move dependency: only \(solvableFirstMoves.count)/\(validFirstMoves) first moves are solvable"
                )
            }
        }
    }
}

import XCTest
@testable import Damaze

/// Generates candidate levels and prints them for curation.
/// These tests produce output for manual review, not automated validation.
final class LevelCurationTests: XCTestCase {

    private func directionName(_ dir: Direction) -> String {
        switch dir {
        case .up: return ".up"
        case .down: return ".down"
        case .left: return ".left"
        case .right: return ".right"
        }
    }

    private func printCandidate(_ gen: GeneratedLevel, label: String) {
        let movesStr = gen.solution.map { directionName($0) }.joined(separator: ", ")
        print("--- \(label) ---")
        print("Grid (\(gen.metrics.gridRows)×\(gen.metrics.gridCols)), \(gen.metrics.solutionLength) moves, \(gen.metrics.floorTileCount) tiles, \(gen.metrics.wallCount) walls:")
        for row in gen.grid {
            print("    \(row),")
        }
        print("Solution: [\(movesStr)]")
        print("")
    }

    func test_generateEasyCandidates() {
        let results = LevelGenerator.generate(config: LevelGenerator.easyConfig, attempts: 2000)
        print("\n=== EASY CANDIDATES (top 10) ===")
        for (i, gen) in results.prefix(10).enumerated() {
            printCandidate(gen, label: "Easy #\(i+1)")
        }
        print("Total easy candidates: \(results.count)")
    }

    func test_generateMediumSmallCandidates() {
        let results = LevelGenerator.generate(config: LevelGenerator.mediumSmallConfig, attempts: 2000)
        print("\n=== MEDIUM-SMALL 5×5 CANDIDATES (top 10) ===")
        for (i, gen) in results.prefix(10).enumerated() {
            printCandidate(gen, label: "MedSmall #\(i+1)")
        }
        print("Total medium-small candidates: \(results.count)")
    }

    func test_generateMediumCandidates() {
        let results = LevelGenerator.generate(config: LevelGenerator.mediumConfig, attempts: 2000)
        print("\n=== MEDIUM 5×6 CANDIDATES (top 10) ===")
        for (i, gen) in results.prefix(10).enumerated() {
            printCandidate(gen, label: "Medium #\(i+1)")
        }
        print("Total medium candidates: \(results.count)")
    }

    func test_generateHardCandidates() {
        let results = LevelGenerator.generate(config: LevelGenerator.hardConfig, attempts: 2000)
        print("\n=== HARD 6×6 CANDIDATES (top 10) ===")
        for (i, gen) in results.prefix(10).enumerated() {
            printCandidate(gen, label: "Hard #\(i+1)")
        }
        print("Total hard candidates: \(results.count)")
    }
}

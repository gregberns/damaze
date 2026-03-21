import XCTest
@testable import Damaze

/// Temporary test class for generating replacement and new levels.
/// These tests output level data for curation into LevelStore.
final class LevelAuditTests: XCTestCase {

    func test_generateReplacements_5x5() {
        // Replacement candidates for levels 8, 9, 10 (currently 5x5 medium)
        let configs: [(String, LevelGenerator.Config)] = [
            ("5x5-A", LevelGenerator.Config(rows: 5, cols: 5, wallDensity: 0.20, minSolutionLength: 8, maxSolutionLength: 12)),
            ("5x5-B", LevelGenerator.Config(rows: 5, cols: 5, wallDensity: 0.25, minSolutionLength: 7, maxSolutionLength: 11)),
            ("6x5-A", LevelGenerator.Config(rows: 6, cols: 5, wallDensity: 0.25, minSolutionLength: 8, maxSolutionLength: 12)),
            ("6x5-B", LevelGenerator.Config(rows: 6, cols: 5, wallDensity: 0.30, minSolutionLength: 7, maxSolutionLength: 11)),
        ]
        for (name, config) in configs {
            print("\n// === REPLACEMENT \(name) ===")
            if let result = LevelGenerator.generate(config: config, maxAttempts: 10000) {
                printLevel(name: name, result: result)
            } else {
                print("// NO LEVEL for \(name)")
            }
        }
    }

    func test_generateReplacement_level12() {
        // Replacement for level 12 (currently 7x4 medium-hard)
        let configs: [(String, LevelGenerator.Config)] = [
            ("7x5-A", LevelGenerator.Config(rows: 7, cols: 5, wallDensity: 0.30, minSolutionLength: 9, maxSolutionLength: 13)),
            ("7x6-A", LevelGenerator.Config(rows: 7, cols: 6, wallDensity: 0.30, minSolutionLength: 10, maxSolutionLength: 14)),
            ("6x6-A", LevelGenerator.Config(rows: 6, cols: 6, wallDensity: 0.30, minSolutionLength: 9, maxSolutionLength: 13)),
        ]
        for (name, config) in configs {
            print("\n// === REPLACEMENT-12 \(name) ===")
            if let result = LevelGenerator.generate(config: config, maxAttempts: 10000) {
                printLevel(name: name, result: result)
            } else {
                print("// NO LEVEL for \(name)")
            }
        }
    }

    func test_generateMoreMedium() {
        // Additional medium levels at various sizes
        let configs: [(String, LevelGenerator.Config)] = [
            ("6x7-M", LevelGenerator.Config(rows: 6, cols: 7, wallDensity: 0.30, minSolutionLength: 9, maxSolutionLength: 14)),
            ("7x6-M", LevelGenerator.Config(rows: 7, cols: 6, wallDensity: 0.30, minSolutionLength: 9, maxSolutionLength: 14)),
            ("8x6-M", LevelGenerator.Config(rows: 8, cols: 6, wallDensity: 0.35, minSolutionLength: 9, maxSolutionLength: 14)),
            ("7x8-M", LevelGenerator.Config(rows: 7, cols: 8, wallDensity: 0.35, minSolutionLength: 9, maxSolutionLength: 14)),
            ("8x8-M", LevelGenerator.Config(rows: 8, cols: 8, wallDensity: 0.40, minSolutionLength: 10, maxSolutionLength: 14)),
            ("9x7-M", LevelGenerator.Config(rows: 9, cols: 7, wallDensity: 0.40, minSolutionLength: 10, maxSolutionLength: 14)),
        ]
        for (name, config) in configs {
            print("\n// === MORE-MEDIUM \(name) ===")
            if let result = LevelGenerator.generate(config: config, maxAttempts: 10000) {
                printLevel(name: name, result: result)
            } else {
                print("// NO LEVEL for \(name)")
            }
        }
    }

    func test_generateMoreHard() {
        // Additional hard levels
        let configs: [(String, LevelGenerator.Config)] = [
            ("10x8-H", LevelGenerator.Config(rows: 10, cols: 8, wallDensity: 0.50, minSolutionLength: 15, maxSolutionLength: 25)),
            ("11x9-H", LevelGenerator.Config(rows: 11, cols: 9, wallDensity: 0.55, minSolutionLength: 15, maxSolutionLength: 25)),
            ("10x10-H", LevelGenerator.Config(rows: 10, cols: 10, wallDensity: 0.55, minSolutionLength: 16, maxSolutionLength: 25)),
            ("12x12-H", LevelGenerator.Config(rows: 12, cols: 12, wallDensity: 0.65, minSolutionLength: 15, maxSolutionLength: 25)),
        ]
        for (name, config) in configs {
            print("\n// === MORE-HARD \(name) ===")
            if let result = LevelGenerator.generate(config: config, maxAttempts: 15000) {
                printLevel(name: name, result: result)
            } else {
                print("// NO LEVEL for \(name)")
            }
        }
    }

    private func printLevel(name: String, result: LevelGenerator.GeneratedLevel) {
        let dirs = result.solution.map { dir -> String in
            switch dir {
            case .up: return ".up"
            case .down: return ".down"
            case .left: return ".left"
            case .right: return ".right"
            }
        }.joined(separator: ", ")
        print("// \(name): \(result.solution.count) moves, score=\(String(format: "%.1f", result.quality.score)), " +
              "viable=\(result.quality.viableFirstMoves), forced=\(result.quality.forcedMoves)")
        print("// Solution: [\(dirs)]")
        print("// Grid:")
        for row in result.grid {
            print("            \(row),")
        }
    }
}

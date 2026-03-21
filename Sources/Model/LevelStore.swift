import Foundation

struct LevelData {
    let name: String
    let colorScheme: LevelColorScheme
    let level: Level
}

enum LevelColorScheme: String {
    case blue
    case green
    case orange
    case purple
    case teal
    case red
}

enum LevelStore {
    // MARK: - Original Hand-Crafted Levels

    static let level1 = LevelData(
        name: "First Steps",
        colorScheme: .blue,
        level: try! Level(grid: [
            [1, 1, 1, 1],
            [1, 0, 0, 1],
            [1, 0, 0, 1],
            [1, 1, 1, 2],
        ])
    )

    static let level2 = LevelData(
        name: "The Notch",
        colorScheme: .green,
        level: try! Level(grid: [
            [1, 1, 1, 1, 0],
            [1, 0, 0, 1, 0],
            [1, 0, 0, 1, 0],
            [1, 1, 1, 1, 1],
            [0, 0, 2, 1, 1],
        ])
    )

    static let level3 = LevelData(
        name: "Backtrack",
        colorScheme: .orange,
        level: try! Level(grid: [
            [0, 1, 1, 1, 0],
            [1, 1, 0, 1, 1],
            [1, 0, 0, 0, 1],
            [1, 1, 0, 1, 1],
            [0, 1, 1, 1, 0],
            [0, 0, 2, 0, 0],
        ])
    )

    // MARK: - Generated Easy Levels

    static let level4 = LevelData(
        name: "The Nook",
        colorScheme: .purple,
        level: try! Level(grid: [
            [1, 1, 2, 1],
            [1, 0, 1, 1],
            [1, 0, 1, 0],
            [1, 1, 1, 1],
        ])
    )

    static let level5 = LevelData(
        name: "Inner Ring",
        colorScheme: .teal,
        level: try! Level(grid: [
            [1, 1, 1, 1],
            [1, 2, 1, 1],
            [1, 1, 1, 1],
            [0, 0, 0, 1],
            [0, 0, 1, 1],
        ])
    )

    // MARK: - Generated Medium Levels

    static let level6 = LevelData(
        name: "The Well",
        colorScheme: .red,
        level: try! Level(grid: [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 1],
            [0, 0, 0, 1, 1],
            [0, 0, 1, 2, 1],
            [0, 0, 1, 1, 1],
            [0, 0, 1, 0, 0],
        ])
    )

    static let level7 = LevelData(
        name: "The Bridge",
        colorScheme: .blue,
        level: try! Level(grid: [
            [0, 1, 1, 1, 1],
            [1, 1, 2, 1, 1],
            [0, 0, 1, 0, 0],
            [0, 1, 1, 0, 0],
            [0, 0, 0, 0, 0],
        ])
    )

    static let level8 = LevelData(
        name: "Crossroads",
        colorScheme: .green,
        level: try! Level(grid: [
            [1, 1, 2, 1, 1],
            [0, 1, 1, 0, 1],
            [0, 1, 1, 1, 1],
            [1, 1, 1, 1, 1],
            [1, 1, 1, 1, 0],
        ])
    )

    static let level9 = LevelData(
        name: "Detour",
        colorScheme: .orange,
        level: try! Level(grid: [
            [0, 1, 1, 1, 1],
            [1, 1, 0, 1, 0],
            [1, 1, 2, 1, 0],
            [1, 0, 1, 0, 0],
            [1, 0, 0, 0, 0],
        ])
    )

    // MARK: - Generated Medium-Hard Levels

    static let level10 = LevelData(
        name: "Descent",
        colorScheme: .purple,
        level: try! Level(grid: [
            [1, 0, 1, 1, 1],
            [1, 2, 1, 0, 1],
            [1, 1, 1, 1, 1],
            [0, 1, 1, 1, 0],
            [0, 0, 1, 1, 0],
            [0, 0, 0, 1, 0],
        ])
    )

    static let level11 = LevelData(
        name: "Tower",
        colorScheme: .teal,
        level: try! Level(grid: [
            [0, 1, 0, 0, 0, 1],
            [0, 1, 0, 0, 0, 1],
            [0, 1, 1, 1, 0, 1],
            [0, 1, 2, 1, 0, 1],
            [0, 0, 0, 1, 1, 1],
            [0, 0, 0, 0, 0, 1],
        ])
    )

    // MARK: - Medium Levels (Generated, Solver-Verified)

    static let level12 = LevelData(
        name: "Divide",
        colorScheme: .blue,
        level: try! Level(grid: [
            [0, 0, 0, 1, 1],
            [1, 1, 0, 1, 1],
            [1, 1, 1, 2, 1],
            [1, 1, 0, 1, 1],
            [1, 1, 1, 1, 1],
        ])
    )

    static let level13 = LevelData(
        name: "Staircase",
        colorScheme: .green,
        level: try! Level(grid: [
            [0, 1, 0, 0, 0],
            [1, 1, 0, 0, 0],
            [1, 1, 1, 0, 0],
            [1, 2, 1, 0, 0],
            [1, 1, 1, 0, 1],
            [0, 1, 1, 1, 1],
        ])
    )

    static let level14 = LevelData(
        name: "Two Towers",
        colorScheme: .orange,
        level: try! Level(grid: [
            [0, 1, 1, 0, 1],
            [1, 1, 1, 0, 1],
            [1, 2, 1, 0, 1],
            [1, 1, 1, 1, 1],
            [0, 1, 0, 0, 1],
            [1, 1, 1, 1, 1],
        ])
    )

    static let level15 = LevelData(
        name: "The Hook",
        colorScheme: .purple,
        level: try! Level(grid: [
            [0, 1, 1, 1, 1],
            [0, 0, 1, 2, 1],
            [1, 1, 1, 1, 1],
            [0, 1, 1, 0, 0],
            [0, 1, 0, 0, 0],
            [0, 1, 0, 0, 0],
        ])
    )

    static let level16 = LevelData(
        name: "Arena",
        colorScheme: .red,
        level: try! Level(grid: [
            [0, 1, 1, 1, 1, 1],
            [1, 1, 1, 1, 0, 1],
            [1, 1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1, 2],
            [1, 1, 1, 1, 1, 0],
            [1, 0, 1, 1, 1, 1],
        ])
    )

    // MARK: - Hard Levels (Generated, Solver-Verified)

    static let level17 = LevelData(
        name: "Wedge",
        colorScheme: .teal,
        level: try! Level(grid: [
            [1, 0, 0, 1, 1, 1],
            [1, 1, 1, 1, 1, 0],
            [1, 1, 1, 1, 1, 0],
            [0, 1, 1, 1, 1, 1],
            [0, 0, 2, 1, 1, 1],
            [0, 0, 1, 1, 1, 1],
        ])
    )

    static let level18 = LevelData(
        name: "Diagonal",
        colorScheme: .blue,
        level: try! Level(grid: [
            [0, 0, 0, 0, 0, 1, 1],
            [0, 0, 1, 1, 2, 1, 1],
            [0, 1, 1, 1, 1, 0, 1],
            [0, 1, 1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1, 0, 0],
            [1, 1, 1, 1, 1, 0, 0],
            [1, 1, 0, 1, 1, 1, 1],
        ])
    )

    static let level19 = LevelData(
        name: "The Void",
        colorScheme: .green,
        level: try! Level(grid: [
            [1, 0, 0, 1, 1, 1, 1],
            [1, 1, 1, 1, 1, 1, 1],
            [1, 1, 1, 1, 1, 1, 1],
            [0, 1, 1, 1, 1, 1, 1],
            [0, 1, 1, 0, 1, 2, 1],
            [0, 1, 1, 0, 0, 0, 1],
            [0, 1, 1, 0, 0, 0, 0],
        ])
    )

    // MARK: - Expert Levels (Generated, Solver-Verified)

    static let level20 = LevelData(
        name: "Expedition",
        colorScheme: .orange,
        level: try! Level(grid: [
            [1, 1, 1, 1, 0, 0, 0, 0],
            [1, 1, 1, 1, 1, 0, 1, 1],
            [1, 0, 0, 1, 1, 1, 1, 1],
            [1, 1, 1, 0, 2, 1, 0, 0],
            [0, 0, 1, 1, 1, 1, 0, 1],
            [0, 0, 1, 1, 1, 1, 1, 1],
            [0, 0, 0, 1, 1, 1, 1, 1],
            [0, 0, 0, 1, 1, 0, 1, 1],
        ])
    )

    static let level21 = LevelData(
        name: "Odyssey",
        colorScheme: .purple,
        level: try! Level(grid: [
            [1, 0, 0, 0, 0, 0, 0, 0, 0],
            [1, 1, 0, 0, 0, 0, 0, 0, 0],
            [2, 1, 1, 1, 1, 0, 0, 0, 0],
            [1, 1, 1, 1, 0, 1, 0, 1, 1],
            [0, 1, 1, 1, 1, 1, 0, 1, 1],
            [1, 1, 1, 0, 0, 1, 0, 1, 1],
            [1, 1, 0, 1, 1, 1, 0, 0, 1],
            [1, 0, 1, 1, 1, 1, 1, 1, 1],
            [1, 0, 0, 0, 1, 1, 1, 1, 0],
        ])
    )

    static let level22 = LevelData(
        name: "Continent",
        colorScheme: .red,
        level: try! Level(grid: [
            [0, 0, 1, 1, 1, 1, 1, 1, 0, 0],
            [0, 0, 1, 2, 1, 1, 1, 1, 1, 0],
            [1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
            [1, 0, 0, 0, 1, 1, 1, 1, 1, 1],
            [0, 0, 0, 0, 0, 0, 0, 1, 1, 0],
            [0, 0, 0, 0, 0, 0, 1, 1, 1, 1],
            [0, 0, 0, 0, 0, 0, 1, 0, 1, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
            [0, 0, 0, 0, 0, 0, 1, 1, 1, 0],
            [0, 0, 0, 0, 1, 1, 1, 0, 0, 0],
        ])
    )

    static let allLevels: [LevelData] = [
        level1, level2, level3, level4, level5, level6,
        level7, level8, level9, level10, level11, level12,
        level13, level14, level15, level16, level17, level18,
        level19, level20, level21, level22,
    ]
}

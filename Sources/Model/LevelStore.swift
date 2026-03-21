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
    // MARK: - Easy Levels (1-5)

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

    // MARK: - Medium Levels (6-19)

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

    // Replaced: was "Crossroads" (33% first-move solvability)
    static let level8 = LevelData(
        name: "Corridors",
        colorScheme: .green,
        level: try! Level(grid: [
            [1, 1, 1, 1, 1],
            [1, 2, 1, 1, 1],
            [1, 0, 1, 1, 1],
            [1, 1, 1, 1, 0],
            [0, 0, 1, 1, 0],
        ])
    )

    // Replaced: was "Detour" (33% first-move solvability)
    static let level9 = LevelData(
        name: "The Ledge",
        colorScheme: .orange,
        level: try! Level(grid: [
            [1, 1, 0, 1, 0],
            [1, 1, 1, 1, 0],
            [0, 0, 2, 1, 0],
            [1, 1, 1, 1, 1],
        ])
    )

    // Replaced: was "Descent" (33% first-move solvability)
    static let level10 = LevelData(
        name: "Alcove",
        colorScheme: .purple,
        level: try! Level(grid: [
            [0, 1, 1, 0],
            [0, 1, 2, 0],
            [1, 1, 1, 1],
            [0, 1, 1, 1],
            [1, 1, 1, 1],
            [0, 1, 0, 1],
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

    // Replaced: was "Labyrinth" (specifically cited as worst offender)
    static let level12 = LevelData(
        name: "The Gallery",
        colorScheme: .red,
        level: try! Level(grid: [
            [0, 1, 1, 1, 1, 1, 1],
            [1, 2, 1, 1, 0, 1, 1],
            [0, 0, 1, 1, 0, 1, 1],
            [0, 0, 1, 1, 0, 1, 1],
            [0, 0, 0, 0, 0, 1, 0],
        ])
    )

    static let level13 = LevelData(
        name: "The Courtyard",
        colorScheme: .blue,
        level: try! Level(grid: [
            [1, 1, 1, 0, 0, 0],
            [1, 0, 2, 0, 1, 0],
            [1, 1, 1, 1, 1, 0],
            [0, 1, 1, 1, 1, 1],
            [0, 1, 1, 1, 1, 1],
            [0, 0, 1, 1, 0, 0],
        ])
    )

    static let level14 = LevelData(
        name: "Stairway",
        colorScheme: .green,
        level: try! Level(grid: [
            [1, 1, 0, 1, 1, 1],
            [1, 1, 1, 1, 0, 1],
            [0, 2, 1, 0, 0, 1],
            [1, 1, 1, 0, 0, 1],
        ])
    )

    static let level15 = LevelData(
        name: "The Attic",
        colorScheme: .orange,
        level: try! Level(grid: [
            [1, 1, 1, 1],
            [0, 0, 1, 1],
            [1, 0, 1, 0],
            [1, 1, 1, 0],
            [1, 2, 0, 0],
            [1, 0, 0, 0],
        ])
    )

    static let level16 = LevelData(
        name: "Pipeline",
        colorScheme: .purple,
        level: try! Level(grid: [
            [1, 2, 1, 1, 1, 1, 1],
            [1, 1, 1, 1, 0, 0, 1],
            [0, 0, 0, 1, 0, 1, 1],
            [0, 0, 0, 1, 1, 1, 1],
            [0, 0, 0, 0, 0, 1, 1],
        ])
    )

    static let level17 = LevelData(
        name: "The Terrace",
        colorScheme: .teal,
        level: try! Level(grid: [
            [0, 1, 1, 0],
            [0, 1, 1, 1],
            [1, 1, 1, 1],
            [1, 1, 1, 1],
            [1, 1, 0, 0],
            [1, 2, 1, 1],
        ])
    )

    static let level18 = LevelData(
        name: "The Basement",
        colorScheme: .red,
        level: try! Level(grid: [
            [0, 1, 1, 0, 0],
            [0, 1, 2, 0, 1],
            [1, 1, 1, 1, 1],
            [1, 0, 1, 1, 0],
        ])
    )

    static let level19 = LevelData(
        name: "Clockwork",
        colorScheme: .blue,
        level: try! Level(grid: [
            [2, 1, 1, 0],
            [1, 0, 1, 0],
            [1, 0, 0, 1],
            [1, 1, 1, 1],
            [0, 0, 0, 1],
            [0, 0, 0, 1],
            [0, 1, 1, 1],
            [0, 1, 1, 1],
            [1, 1, 1, 0],
        ])
    )

    // MARK: - Hard Levels (20-30)

    static let level20 = LevelData(
        name: "The Cascade",
        colorScheme: .green,
        level: try! Level(grid: [
            [0, 0, 0, 0, 0, 1, 0],
            [0, 0, 0, 0, 0, 1, 1],
            [0, 0, 0, 0, 1, 1, 1],
            [0, 0, 0, 1, 1, 1, 1],
            [0, 0, 0, 0, 1, 0, 1],
            [0, 0, 0, 0, 1, 2, 0],
            [0, 0, 0, 0, 1, 1, 1],
        ])
    )

    static let level21 = LevelData(
        name: "Grand Tour",
        colorScheme: .orange,
        level: try! Level(grid: [
            [1, 0, 0, 0, 0, 2, 1],
            [1, 0, 0, 0, 1, 1, 1],
            [1, 1, 1, 1, 1, 0, 1],
            [1, 0, 1, 0, 0, 1, 1],
            [1, 0, 1, 1, 1, 1, 0],
            [0, 0, 1, 0, 0, 0, 0],
        ])
    )

    static let level22 = LevelData(
        name: "Switchback",
        colorScheme: .purple,
        level: try! Level(grid: [
            [1, 1, 1, 1, 1, 1],
            [0, 1, 0, 0, 0, 1],
            [0, 1, 1, 1, 1, 0],
            [0, 0, 1, 1, 1, 1],
            [0, 0, 0, 2, 0, 1],
            [0, 0, 0, 0, 1, 1],
        ])
    )

    static let level23 = LevelData(
        name: "Maze Runner",
        colorScheme: .teal,
        level: try! Level(grid: [
            [0, 0, 1, 1, 0, 1],
            [0, 1, 1, 1, 0, 1],
            [1, 1, 2, 1, 1, 1],
            [1, 1, 1, 1, 1, 1],
            [1, 1, 1, 0, 0, 1],
            [0, 1, 1, 0, 1, 1],
        ])
    )

    static let level24 = LevelData(
        name: "Spider Web",
        colorScheme: .red,
        level: try! Level(grid: [
            [0, 1, 1, 0, 0, 1, 0, 0],
            [1, 1, 1, 0, 1, 1, 0, 0],
            [1, 1, 1, 0, 1, 1, 2, 0],
            [1, 0, 1, 1, 1, 0, 1, 0],
            [0, 0, 0, 1, 1, 0, 0, 0],
            [0, 0, 0, 1, 1, 1, 0, 0],
            [0, 0, 0, 0, 1, 1, 0, 0],
            [0, 0, 0, 0, 0, 1, 1, 1],
        ])
    )

    static let level25 = LevelData(
        name: "The Cathedral",
        colorScheme: .blue,
        level: try! Level(grid: [
            [1, 1, 1, 1, 0, 1, 1, 1],
            [0, 0, 1, 1, 1, 1, 1, 0],
            [1, 1, 1, 1, 1, 0, 1, 0],
            [1, 2, 0, 1, 1, 0, 0, 0],
        ])
    )

    static let level26 = LevelData(
        name: "Serpentine",
        colorScheme: .green,
        level: try! Level(grid: [
            [0, 0, 0, 1, 1, 1, 0, 0, 0],
            [0, 1, 1, 0, 2, 1, 0, 0, 0],
            [1, 1, 1, 0, 1, 1, 0, 0, 0],
            [1, 1, 1, 1, 1, 1, 1, 1, 0],
            [0, 1, 0, 1, 0, 0, 0, 1, 0],
            [0, 1, 1, 1, 1, 1, 0, 1, 1],
            [0, 1, 1, 1, 0, 0, 0, 0, 0],
            [1, 1, 1, 1, 0, 0, 0, 0, 0],
            [1, 0, 1, 1, 0, 0, 0, 0, 0],
        ])
    )

    static let level27 = LevelData(
        name: "Iron Maze",
        colorScheme: .orange,
        level: try! Level(grid: [
            [0, 0, 0, 0, 1],
            [0, 0, 1, 1, 1],
            [0, 0, 0, 2, 1],
            [0, 1, 1, 1, 0],
            [0, 1, 1, 1, 1],
            [1, 1, 1, 0, 1],
            [1, 0, 0, 1, 1],
        ])
    )

    static let level28 = LevelData(
        name: "The Gauntlet",
        colorScheme: .purple,
        level: try! Level(grid: [
            [1, 0, 0, 0, 0, 0, 0, 0, 0],
            [1, 0, 0, 0, 0, 0, 0, 0, 0],
            [1, 1, 1, 0, 1, 1, 0, 1, 0],
            [0, 1, 1, 1, 2, 1, 1, 1, 0],
            [0, 1, 1, 1, 0, 1, 1, 1, 1],
            [0, 1, 0, 1, 0, 1, 0, 0, 0],
        ])
    )

    static let level29 = LevelData(
        name: "Deep Descent",
        colorScheme: .teal,
        level: try! Level(grid: [
            [0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 1, 1, 0],
            [0, 0, 0, 0, 0, 0, 0, 1, 1, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
            [0, 0, 0, 1, 0, 0, 2, 1, 1, 0],
            [0, 1, 1, 1, 1, 1, 1, 0, 1, 0],
            [1, 1, 1, 1, 0, 1, 1, 0, 1, 0],
            [1, 1, 0, 0, 0, 1, 0, 0, 0, 0],
            [1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
        ])
    )

    static let level30 = LevelData(
        name: "The Labyrinth",
        colorScheme: .red,
        level: try! Level(grid: [
            [0, 0, 0, 0, 0, 0, 0, 1],
            [0, 0, 0, 0, 0, 0, 0, 1],
            [0, 0, 0, 0, 0, 0, 0, 1],
            [0, 0, 0, 0, 0, 0, 1, 2],
            [0, 0, 1, 1, 0, 0, 1, 1],
            [1, 1, 1, 0, 0, 1, 1, 0],
            [0, 1, 1, 1, 1, 1, 1, 1],
            [0, 0, 0, 0, 1, 1, 1, 0],
            [0, 0, 0, 0, 1, 1, 0, 0],
            [0, 0, 0, 0, 1, 1, 0, 0],
        ])
    )

    static let allLevels: [LevelData] = [
        level1, level2, level3, level4, level5,
        level6, level7, level8, level9, level10,
        level11, level12, level13, level14, level15,
        level16, level17, level18, level19, level20,
        level21, level22, level23, level24, level25,
        level26, level27, level28, level29, level30,
    ]
}

import Foundation

enum LevelProgress {
    private static let completedKey = "completedLevels"
    private static let bestMovesKeyPrefix = "bestMoves_"

    static func isCompleted(levelIndex: Int) -> Bool {
        completedIndices().contains(levelIndex)
    }

    static func completedIndices() -> Set<Int> {
        let array = UserDefaults.standard.array(forKey: completedKey) as? [Int] ?? []
        return Set(array)
    }

    static func markCompleted(levelIndex: Int, moves: Int) {
        var completed = completedIndices()
        completed.insert(levelIndex)
        UserDefaults.standard.set(Array(completed), forKey: completedKey)

        let key = bestMovesKeyPrefix + "\(levelIndex)"
        let existing = UserDefaults.standard.integer(forKey: key)
        if existing == 0 || moves < existing {
            UserDefaults.standard.set(moves, forKey: key)
        }
    }

    static func bestMoves(levelIndex: Int) -> Int? {
        let key = bestMovesKeyPrefix + "\(levelIndex)"
        let value = UserDefaults.standard.integer(forKey: key)
        return value > 0 ? value : nil
    }

    static func nextUnsolvedIndex() -> Int? {
        let completed = completedIndices()
        for i in 0..<LevelStore.allLevels.count {
            if !completed.contains(i) {
                return i
            }
        }
        return nil
    }
}

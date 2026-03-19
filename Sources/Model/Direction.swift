enum Direction: CaseIterable {
    case up, down, left, right

    var rowDelta: Int {
        switch self {
        case .up: return -1
        case .down: return 1
        case .left: return 0
        case .right: return 0
        }
    }

    var colDelta: Int {
        switch self {
        case .up: return 0
        case .down: return 0
        case .left: return -1
        case .right: return 1
        }
    }
}

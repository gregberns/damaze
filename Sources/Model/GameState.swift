struct GameState {
    let level: Level
    var ballPosition: GridPosition
    var paintedTiles: Set<GridPosition>
    var moveHistory: [Direction]
    var phase: GamePhase
    var moveCount: Int

    var isComplete: Bool {
        paintedTiles.count == level.floorTileCount
    }
}

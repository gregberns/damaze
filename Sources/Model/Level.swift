enum LevelError: Error {
    case emptyGrid
    case raggedGrid
    case invalidCellValue(Int)
    case noStartPosition
    case multipleStartPositions
    case gridTooLarge(rows: Int, cols: Int)
}

struct Level {
    let grid: [[CellType]]
    let rows: Int
    let cols: Int
    let startPosition: GridPosition
    let floorTileCount: Int

    init(grid rawGrid: [[Int]]) throws {
        guard !rawGrid.isEmpty, !rawGrid[0].isEmpty else {
            throw LevelError.emptyGrid
        }

        let rows = rawGrid.count
        let cols = rawGrid[0].count

        guard rows <= 7, cols <= 7 else {
            throw LevelError.gridTooLarge(rows: rows, cols: cols)
        }

        var convertedGrid: [[CellType]] = []
        var start: GridPosition?
        var floorCount = 0

        for (r, row) in rawGrid.enumerated() {
            guard row.count == cols else {
                throw LevelError.raggedGrid
            }
            var convertedRow: [CellType] = []
            for (c, value) in row.enumerated() {
                guard let cellType = CellType(rawValue: value) else {
                    throw LevelError.invalidCellValue(value)
                }
                convertedRow.append(cellType)
                if cellType == .start {
                    guard start == nil else {
                        throw LevelError.multipleStartPositions
                    }
                    start = GridPosition(row: r, col: c)
                    floorCount += 1
                } else if cellType == .floor {
                    floorCount += 1
                }
            }
            convertedGrid.append(convertedRow)
        }

        guard let startPos = start else {
            throw LevelError.noStartPosition
        }

        self.grid = convertedGrid
        self.rows = rows
        self.cols = cols
        self.startPosition = startPos
        self.floorTileCount = floorCount
    }
}

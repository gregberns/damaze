import SwiftUI

struct GridView: View {
    let level: Level
    let paintedTiles: Set<GridPosition>
    let ballPosition: GridPosition
    let levelColor: Color
    let isBumping: Bool
    let bumpDirection: Direction?
    let shouldPulse: Bool

    var body: some View {
        GeometryReader { geometry in
            let padding: CGFloat = 16
            let availableWidth = geometry.size.width - padding * 2
            let availableHeight = geometry.size.height - padding * 2
            let cellSize = min(availableWidth / CGFloat(level.cols), availableHeight / CGFloat(level.rows))
            let gridWidth = cellSize * CGFloat(level.cols)
            let gridHeight = cellSize * CGFloat(level.rows)

            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    ForEach(0..<level.rows, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<level.cols, id: \.self) { col in
                                let pos = GridPosition(row: row, col: col)
                                CellView(
                                    cellType: level.grid[row][col],
                                    isPainted: paintedTiles.contains(pos),
                                    levelColor: levelColor,
                                    cellSize: cellSize
                                )
                            }
                        }
                    }
                }

                BallView(
                    position: ballPosition,
                    levelColor: levelColor,
                    cellSize: cellSize,
                    isBumping: isBumping,
                    bumpDirection: bumpDirection,
                    shouldPulse: shouldPulse
                )
                .allowsHitTesting(false)
            }
            .frame(width: gridWidth, height: gridHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

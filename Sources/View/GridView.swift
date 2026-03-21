import SwiftUI

struct GridView: View {
    let level: Level
    let paintedTiles: Set<GridPosition>
    let ballPosition: GridPosition
    let levelColor: Color
    let isBumping: Bool
    let bumpDirection: Direction?
    let shouldPulse: Bool
    let isGridPulsing: Bool

    @Environment(\.colorScheme) private var colorScheme

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
                                let isPainted = paintedTiles.contains(pos)
                                CellView(
                                    cellType: level.grid[row][col],
                                    isPainted: isPainted,
                                    levelColor: levelColor,
                                    cellSize: cellSize
                                )
                                .scaleEffect(isPainted && isGridPulsing ? 1.05 : 1.0)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(boardColor)
                        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                        .padding(-4)
                )

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

    private var boardColor: Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.08, blue: 0.10)
            : Color(red: 0.30, green: 0.29, blue: 0.32)
    }
}

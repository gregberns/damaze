import SwiftUI

struct BallView: View {
    let position: GridPosition
    let levelColor: Color
    let cellSize: CGFloat

    var body: some View {
        let diameter = cellSize * 0.7
        let x = CGFloat(position.col) * cellSize + cellSize / 2
        let y = CGFloat(position.row) * cellSize + cellSize / 2

        Circle()
            .fill(levelColor)
            .frame(width: diameter, height: diameter)
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            .position(x: x, y: y)
    }
}

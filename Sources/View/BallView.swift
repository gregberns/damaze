import SwiftUI

struct BallView: View {
    let position: GridPosition
    let levelColor: Color
    let cellSize: CGFloat
    let isBumping: Bool
    let bumpDirection: Direction?
    let shouldPulse: Bool

    var body: some View {
        let diameter = cellSize * 0.7
        let x = CGFloat(position.col) * cellSize + cellSize / 2
        let y = CGFloat(position.row) * cellSize + cellSize / 2

        Circle()
            .fill(levelColor)
            .frame(width: diameter, height: diameter)
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            .scaleEffect(shouldPulse ? 1.08 : 1.0)
            .animation(
                shouldPulse
                    ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                    : .default,
                value: shouldPulse
            )
            .offset(bumpOffset)
            .animation(
                isBumping
                    ? .spring(response: 0.15, dampingFraction: 0.5)
                    : .spring(response: 0.15, dampingFraction: 0.5),
                value: isBumping
            )
            .position(x: x, y: y)
    }

    private var bumpOffset: CGSize {
        guard isBumping, let direction = bumpDirection else {
            return .zero
        }
        return CGSize(
            width: CGFloat(direction.colDelta) * 2,
            height: CGFloat(direction.rowDelta) * 2
        )
    }
}

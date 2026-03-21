import SwiftUI

struct BallView: View {
    let position: GridPosition
    let levelColor: Color
    let cellSize: CGFloat
    let isBumping: Bool
    let bumpDirection: Direction?
    let shouldPulse: Bool

    @State private var isGlowing = false

    var body: some View {
        let diameter = cellSize * 0.65
        let x = CGFloat(position.col) * cellSize + cellSize / 2
        let y = CGFloat(position.row) * cellSize + cellSize / 2

        ZStack {
            // Glow layer (idle breathing animation)
            Circle()
                .fill(levelColor)
                .frame(width: diameter * 1.5, height: diameter * 1.5)
                .blur(radius: diameter * 0.25)
                .opacity(isGlowing ? 0.5 : 0.15)

            // Cast shadow
            Ellipse()
                .fill(Color.black.opacity(0.3))
                .frame(width: diameter * 0.75, height: diameter * 0.3)
                .offset(y: diameter * 0.4)
                .blur(radius: 3)

            // Dark base (visible at edges for 3D depth)
            Circle()
                .fill(Color.black)
                .frame(width: diameter, height: diameter)

            // Ball surface with 3D radial gradient
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            levelColor,
                            levelColor.opacity(0.45)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: diameter * 0.05,
                        endRadius: diameter * 0.5
                    )
                )
                .frame(width: diameter, height: diameter)

            // Specular highlight
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.8),
                            Color.white.opacity(0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: diameter * 0.18
                    )
                )
                .frame(width: diameter * 0.35, height: diameter * 0.25)
                .offset(x: -diameter * 0.1, y: -diameter * 0.15)
        }
        .offset(bumpOffset)
        .animation(
            isBumping
                ? .spring(response: 0.15, dampingFraction: 0.5)
                : .default,
            value: isBumping
        )
        .position(x: x, y: y)
        .onChange(of: shouldPulse) { _, pulse in
            if pulse {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    isGlowing = false
                }
            }
        }
        .onAppear {
            if shouldPulse {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        isGlowing = true
                    }
                }
            }
        }
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

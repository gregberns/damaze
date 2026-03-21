import SwiftUI

struct BallView: View {
    let position: GridPosition
    let levelColor: Color
    let cellSize: CGFloat
    let isBumping: Bool
    let bumpDirection: Direction?
    let shouldPulse: Bool

    @State private var glowActive = false

    var body: some View {
        let diameter = cellSize * 0.7
        let x = CGFloat(position.col) * cellSize + cellSize / 2
        let y = CGFloat(position.row) * cellSize + cellSize / 2

        ZStack {
            // Main ball with radial gradient for 3D appearance
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            levelColor.opacity(0.85),
                            levelColor,
                            levelColor.opacity(0.55)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.30),
                        startRadius: 0,
                        endRadius: diameter * 0.55
                    )
                )
                .frame(width: diameter, height: diameter)
                .shadow(color: .black.opacity(0.3), radius: 3, x: 1, y: 3)

            // Specular highlight
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.55), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: diameter * 0.22
                    )
                )
                .frame(width: diameter * 0.38, height: diameter * 0.28)
                .offset(x: -diameter * 0.1, y: -diameter * 0.14)
        }
        // Glow breathing replaces the old scale pulse
        .shadow(
            color: levelColor.opacity(glowActive ? 0.55 : 0.12),
            radius: glowActive ? 10 : 4
        )
        .offset(bumpOffset)
        .animation(
            isBumping
                ? .spring(response: 0.15, dampingFraction: 0.5)
                : .default,
            value: isBumping
        )
        .position(x: x, y: y)
        .onChange(of: shouldPulse) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    glowActive = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    glowActive = false
                }
            }
        }
        .onAppear {
            if shouldPulse {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        glowActive = true
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

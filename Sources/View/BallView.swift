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
            // Shadow disc beneath the ball (contact shadow)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.black.opacity(0.25), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: diameter * 0.45
                    )
                )
                .frame(width: diameter * 0.8, height: diameter * 0.35)
                .offset(y: diameter * 0.32)

            // Main ball body: strong radial gradient for 3D sphere
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            levelColor.opacity(0.6),
                            levelColor.opacity(0.85),
                            levelColor,
                            levelColor.opacity(0.7),
                            levelColor.opacity(0.4)
                        ],
                        center: UnitPoint(x: 0.38, y: 0.32),
                        startRadius: 0,
                        endRadius: diameter * 0.56
                    )
                )
                .frame(width: diameter, height: diameter)

            // Rim light (subtle edge highlight on bottom-right, simulating reflected light)
            Circle()
                .strokeBorder(
                    AngularGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .clear, location: 0.5),
                            .init(color: .white.opacity(0.15), location: 0.7),
                            .init(color: .clear, location: 0.85),
                            .init(color: .clear, location: 1.0)
                        ],
                        center: .center
                    ),
                    lineWidth: diameter * 0.06
                )
                .frame(width: diameter * 0.92, height: diameter * 0.92)

            // Primary specular highlight (upper-left light source)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.65), .white.opacity(0.15), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: diameter * 0.2
                    )
                )
                .frame(width: diameter * 0.35, height: diameter * 0.25)
                .offset(x: -diameter * 0.12, y: -diameter * 0.15)

            // Secondary micro-highlight (adds realism)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: diameter * 0.08
                    )
                )
                .frame(width: diameter * 0.12, height: diameter * 0.08)
                .offset(x: -diameter * 0.18, y: -diameter * 0.22)
        }
        // Drop shadow for depth
        .shadow(color: .black.opacity(0.3), radius: 4, x: 1.5, y: 3)
        // Glow breathing (replaces old scale pulse)
        .shadow(
            color: levelColor.opacity(glowActive ? 0.5 : 0.1),
            radius: glowActive ? 10 : 3
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

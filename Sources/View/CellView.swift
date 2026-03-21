import SwiftUI

struct CellView: View {
    let cellType: CellType
    let isPainted: Bool
    let levelColor: Color
    let cellSize: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch cellType {
        case .wall:
            wallCell
        case .floor, .start:
            floorCell
        }
    }

    // MARK: - Wall: raised block with multi-edge bevel

    private var wallCell: some View {
        ZStack {
            // Base fill
            Rectangle()
                .fill(wallBaseColor)

            // Top-left highlight edge (light hitting raised surface)
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(colorScheme == .dark ? 0.12 : 0.22), location: 0),
                            .init(color: .clear, location: 0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(colorScheme == .dark ? 0.08 : 0.15), location: 0),
                            .init(color: .clear, location: 0.35)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Bottom-right shadow edge (recessed shadow)
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.65),
                            .init(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.15), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.65),
                            .init(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.12), location: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            // Inset border to separate blocks
            Rectangle()
                .strokeBorder(
                    colorScheme == .dark
                        ? Color.black.opacity(0.4)
                        : Color.black.opacity(0.12),
                    lineWidth: 0.5
                )
        }
        .frame(width: cellSize, height: cellSize)
    }

    // MARK: - Floor: recessed surface with grid lines, vibrant paint

    private var floorCell: some View {
        ZStack {
            if isPainted {
                // Painted tile: gradient fill for "fresh paint" look
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                levelColor.opacity(paintOpacity + 0.08),
                                levelColor.opacity(paintOpacity),
                                levelColor.opacity(paintOpacity - 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                // Unpainted floor: subtle recessed look
                Rectangle()
                    .fill(floorBaseColor)

                // Subtle inner vignette for depth
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [.clear, .black.opacity(colorScheme == .dark ? 0.06 : 0.03)],
                            center: .center,
                            startRadius: cellSize * 0.2,
                            endRadius: cellSize * 0.7
                        )
                    )
            }

            // Grid lines
            Rectangle()
                .strokeBorder(gridLineColor, lineWidth: 0.5)
        }
        .frame(width: cellSize, height: cellSize)
    }

    // MARK: - Theme Colors

    private var wallBaseColor: Color {
        colorScheme == .dark
            ? Color(red: 0.16, green: 0.14, blue: 0.13)
            : Color(red: 0.30, green: 0.27, blue: 0.24)
    }

    private var floorBaseColor: Color {
        colorScheme == .dark
            ? Color(red: 0.26, green: 0.24, blue: 0.22)
            : Color(red: 0.93, green: 0.90, blue: 0.86)
    }

    private var paintOpacity: Double {
        colorScheme == .dark ? 0.75 : 0.80
    }

    private var gridLineColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color.black.opacity(0.07)
    }
}

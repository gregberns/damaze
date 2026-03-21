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

    // MARK: - Wall: raised bevel effect

    private var wallCell: some View {
        Rectangle()
            .fill(wallBaseColor)
            .overlay(
                LinearGradient(
                    colors: [.white.opacity(0.1), .clear, .black.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: cellSize, height: cellSize)
    }

    // MARK: - Floor: visible grid lines, vibrant paint

    private var floorCell: some View {
        Rectangle()
            .fill(isPainted ? levelColor.opacity(paintOpacity) : floorBaseColor)
            .overlay(
                Rectangle()
                    .strokeBorder(gridLineColor, lineWidth: 0.5)
            )
            .frame(width: cellSize, height: cellSize)
    }

    // MARK: - Theme Colors

    private var wallBaseColor: Color {
        colorScheme == .dark
            ? Color(red: 0.18, green: 0.16, blue: 0.14)
            : Color(red: 0.25, green: 0.22, blue: 0.20)
    }

    private var floorBaseColor: Color {
        colorScheme == .dark
            ? Color(red: 0.28, green: 0.26, blue: 0.24)
            : Color(red: 0.92, green: 0.89, blue: 0.85)
    }

    private var paintOpacity: Double {
        colorScheme == .dark ? 0.7 : 0.75
    }

    private var gridLineColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.black.opacity(0.08)
    }
}

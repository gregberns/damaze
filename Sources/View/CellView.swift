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

    private var wallCell: some View {
        Rectangle()
            .fill(wallColor)
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.1), location: 0),
                        .init(color: .clear, location: 0.4),
                        .init(color: Color.black.opacity(0.15), location: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Rectangle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.black.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .frame(width: cellSize, height: cellSize)
    }

    private var floorCell: some View {
        Rectangle()
            .fill(isPainted ? levelColor.opacity(0.75) : floorColor)
            .overlay(
                Rectangle()
                    .strokeBorder(gridLineColor, lineWidth: 0.5)
            )
            .frame(width: cellSize, height: cellSize)
    }

    private var wallColor: Color {
        colorScheme == .dark
            ? Color(red: 0.12, green: 0.11, blue: 0.14)
            : Color(red: 0.25, green: 0.24, blue: 0.28)
    }

    private var floorColor: Color {
        colorScheme == .dark
            ? Color(red: 0.22, green: 0.21, blue: 0.24)
            : Color(red: 0.92, green: 0.90, blue: 0.87)
    }

    private var gridLineColor: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.05)
            : Color.black.opacity(0.08)
    }
}

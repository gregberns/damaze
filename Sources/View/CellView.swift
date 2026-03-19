import SwiftUI

struct CellView: View {
    let cellType: CellType
    let isPainted: Bool
    let levelColor: Color
    let cellSize: CGFloat

    var body: some View {
        Rectangle()
            .fill(fillColor)
            .frame(width: cellSize, height: cellSize)
    }

    private var fillColor: Color {
        switch cellType {
        case .wall:
            return Color(white: 0.2)
        case .floor, .start:
            if isPainted {
                return levelColor.opacity(0.35)
            }
            return Color(white: 0.95)
        }
    }
}

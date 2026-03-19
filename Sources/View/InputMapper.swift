import CoreGraphics

enum InputMapper {
    static func direction(from translation: CGSize) -> Direction? {
        let dx = translation.width
        let dy = translation.height

        guard max(abs(dx), abs(dy)) >= 20 else {
            return nil
        }

        if abs(dx) > abs(dy) {
            return dx > 0 ? .right : .left
        } else {
            return dy > 0 ? .down : .up
        }
    }
}

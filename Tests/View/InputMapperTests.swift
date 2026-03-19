import XCTest
import CoreGraphics
@testable import Damaze

final class InputMapperTests: XCTestCase {

    // #41
    func test_direction_rightSwipe_returnsRight() {
        let result = InputMapper.direction(from: CGSize(width: 50, height: 10))
        XCTAssertEqual(result, .right)
    }

    // #42
    func test_direction_leftSwipe_returnsLeft() {
        let result = InputMapper.direction(from: CGSize(width: -50, height: 10))
        XCTAssertEqual(result, .left)
    }

    // #43
    func test_direction_upSwipe_returnsUp() {
        let result = InputMapper.direction(from: CGSize(width: 5, height: -60))
        XCTAssertEqual(result, .up)
    }

    // #44
    func test_direction_downSwipe_returnsDown() {
        let result = InputMapper.direction(from: CGSize(width: -5, height: 60))
        XCTAssertEqual(result, .down)
    }

    // #45
    func test_direction_belowThreshold_returnsNil() {
        let result = InputMapper.direction(from: CGSize(width: 10, height: 10))
        XCTAssertNil(result)
    }

    // #46
    func test_direction_exactlyAtThreshold_returnsNil() {
        let result = InputMapper.direction(from: CGSize(width: 14, height: 14))
        XCTAssertNil(result)
    }

    // #47
    func test_direction_diagonalEqual_returnsVertical() {
        let result = InputMapper.direction(from: CGSize(width: 50, height: -50))
        XCTAssertEqual(result, .up)
    }
}

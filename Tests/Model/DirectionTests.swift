import XCTest
@testable import Damaze

final class DirectionTests: XCTestCase {
    func test_direction_upDeltas() {
        XCTAssertEqual(Direction.up.rowDelta, -1)
        XCTAssertEqual(Direction.up.colDelta, 0)
    }

    func test_direction_downDeltas() {
        XCTAssertEqual(Direction.down.rowDelta, 1)
        XCTAssertEqual(Direction.down.colDelta, 0)
    }

    func test_direction_leftDeltas() {
        XCTAssertEqual(Direction.left.rowDelta, 0)
        XCTAssertEqual(Direction.left.colDelta, -1)
    }

    func test_direction_rightDeltas() {
        XCTAssertEqual(Direction.right.rowDelta, 0)
        XCTAssertEqual(Direction.right.colDelta, 1)
    }

    func test_direction_caseIterable_hasFourCases() {
        XCTAssertEqual(Direction.allCases.count, 4)
    }
}

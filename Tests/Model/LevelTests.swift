import XCTest
@testable import Damaze

final class LevelTests: XCTestCase {
    // #26
    func test_levelInit_validGrid_succeeds() throws {
        let level = try Level(grid: [
            [0, 1, 0],
            [1, 2, 1],
            [0, 1, 0],
        ])
        XCTAssertEqual(level.rows, 3)
        XCTAssertEqual(level.cols, 3)
    }

    // #27
    func test_levelInit_noStartPosition_throws() {
        XCTAssertThrowsError(try Level(grid: [
            [1, 1, 1],
            [1, 0, 1],
            [1, 1, 1],
        ]))
    }

    // #28
    func test_levelInit_multipleStartPositions_throws() {
        XCTAssertThrowsError(try Level(grid: [
            [2, 1, 2],
            [1, 0, 1],
            [1, 1, 1],
        ]))
    }

    // #29
    func test_levelInit_allWallsNoStart_throws() {
        XCTAssertThrowsError(try Level(grid: [
            [0, 0, 0],
            [0, 0, 0],
            [0, 0, 0],
        ]))
    }

    // #30
    func test_levelInit_raggedArray_throws() {
        XCTAssertThrowsError(try Level(grid: [
            [1, 2, 1],
            [1, 0],
            [1, 1, 1],
        ]))
    }

    // #31
    func test_levelInit_emptyGrid_throws() {
        XCTAssertThrowsError(try Level(grid: []))
    }

    // #32
    func test_levelInit_invalidCellValue_throws() {
        XCTAssertThrowsError(try Level(grid: [
            [2, 3, 1],
        ]))
    }

    // #33
    func test_levelInit_computesFloorTileCount() throws {
        let level = try Level(grid: [
            [1, 1, 1, 1],
            [1, 0, 0, 1],
            [1, 0, 0, 1],
            [1, 1, 1, 2],
        ])
        XCTAssertEqual(level.floorTileCount, 12)
    }

    // #34
    func test_levelInit_extractsStartPosition() throws {
        let level = try Level(grid: [
            [1, 1, 1, 1],
            [1, 0, 0, 1],
            [1, 0, 0, 1],
            [1, 1, 1, 2],
        ])
        XCTAssertEqual(level.startPosition, GridPosition(row: 3, col: 3))
    }

    // #35
    func test_levelInit_gridTooLarge_throws() {
        let row = [2, 1, 1, 1, 1, 1, 1, 1]
        let grid = Array(repeating: row, count: 8)
        XCTAssertThrowsError(try Level(grid: grid))
    }
}

import XCTest
@testable import TypingPet
final class FolderPlanTests: XCTestCase {
    func urls(_ names: [String]) -> [URL] { names.map { URL(fileURLWithPath: "/test/" + $0) } }
    func testCompleteFolderMatchesCaseInsensitiveAndWeightsTpose() throws {
        let p = try FolderPlan(files: urls(["basic.png", "Left.png", "RIGHT.webp", "T.png", "space.png", "1.png", "readme.txt"]))
        XCTAssertEqual(p.files.count, 6)
        XCTAssertEqual(p.left?.lastPathComponent, "Left.png")
        XCTAssertEqual(p.poses.map(\.lastPathComponent), ["T.png", "T.png", "space.png", "T.png", "1.png"])
    }
    func testMissingIdleFails() { XCTAssertThrowsError(try FolderPlan(files: urls(["left.png"]))) }
    func testAmbiguousStatesFailDeterministically() { XCTAssertThrowsError(try FolderPlan(files: urls(["basic.png", "idle.gif"]))) }
    func testIdleOnlyWorks() throws {
        let p = try FolderPlan(files: urls(["待机.apng"]))
        XCTAssertNil(p.left); XCTAssertTrue(p.poses.isEmpty); XCTAssertEqual(p.files.count, 1)
    }
    func testOnlyTposeDoesNotRequireOtherPoses() throws {
        let p = try FolderPlan(files: urls(["idle.gif", "tpose.webp"]))
        XCTAssertEqual(p.poses.count, 5); XCTAssertEqual(p.files.count, 2)
    }
}

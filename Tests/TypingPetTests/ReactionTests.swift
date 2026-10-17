import XCTest
@testable import TypingPet
final class ReactionTests: XCTestCase {
    func testAlternationAndIdleDeadline() {
        var r = Reaction()
        XCTAssertTrue(r.key(at: 10))
        XCTAssertTrue(r.active(at: 10.17))
        XCTAssertFalse(r.active(at: 10.19))
        XCTAssertFalse(r.key(at: 11))
    }
    func testRapidTypingExtendsDeadline() {
        var r = Reaction()
        _ = r.key(at: 0)
        _ = r.key(at: 0.15)
        XCTAssertTrue(r.active(at: 0.3))
        XCTAssertFalse(r.active(at: 0.34))
    }
    func testCharacterSettingsRoundTrip() throws {
        let id = UUID()
        var p = Preferences()
        p.selected = id
        p.characters = [Character(id: id, name: "我的猫", idle: "idle.webp", left: "left.apng", right: "right.gif")]
        let decoded = try JSONDecoder().decode(Preferences.self, from: JSONEncoder().encode(p))
        XCTAssertEqual(decoded.selected, id)
        XCTAssertEqual(decoded.characters, p.characters)
    }
}

final class PostTypingTests: XCTestCase {
    func testIdleDoesNotSpontaneouslyPose() {
        let r = Reaction()
        XCTAssertEqual(r.phase(at: 100), .idle)
    }
    func testTypingThenPoseThenIdle() {
        var r = Reaction()
        _ = r.key(at: 10)
        XCTAssertEqual(r.phase(at: 10.1), .typing)
        XCTAssertEqual(r.phase(at: 10.3), .idle)
        XCTAssertEqual(r.phase(at: 10.56), .pose(0))
        XCTAssertEqual(r.phase(at: 12.16), .idle)
    }
    func testNewKeyInterruptsPose() {
        var r = Reaction()
        _ = r.key(at: 10)
        XCTAssertEqual(r.phase(at: 11), .pose(0))
        _ = r.key(at: 11)
        XCTAssertEqual(r.phase(at: 11.01), .typing)
        XCTAssertEqual(r.phase(at: 11.56), .pose(1))
    }
    func testContinuousTypingDefersPose() {
        var r = Reaction()
        _ = r.key(at: 10)
        _ = r.key(at: 10.4)
        _ = r.key(at: 10.8)
        XCTAssertEqual(r.phase(at: 11), .idle)
        XCTAssertEqual(r.phase(at: 11.36), .pose(0))
    }
    func testPauseResetCancelsPendingPose() {
        var r = Reaction()
        _ = r.key(at: 10)
        r.reset()
        XCTAssertEqual(r.phase(at: 11), .idle)
    }
    func testLegacyCharacterDecodesWithoutPostTypingField() throws {
        let json = "{\"id\":\"00000000-0000-0000-0000-000000000001\",\"name\":\"George\",\"idle\":\"george-basic.png\"}"
        let c = try JSONDecoder().decode(Character.self, from: Data(json.utf8))
        XCTAssertNil(c.afterTyping)
    }
}

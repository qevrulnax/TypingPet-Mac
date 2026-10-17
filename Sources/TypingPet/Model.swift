import Foundation

struct Character: Codable, Equatable {
    var id: UUID
    var name: String
    var idle: String
    var left: String?
    var right: String?
    var afterTyping: [String]? = nil
}
enum ReactionPhase: Equatable {
    case idle
    case typing
    case pose(Int)
}
struct Reaction {
    private(set) var alternate = false
    private(set) var deadline: TimeInterval = 0
    private var lastKey: TimeInterval?
    private var burstCount = 0
    private var poseIndex = 0
    mutating func key(at time: TimeInterval) -> Bool {
        if lastKey == nil || time - lastKey! >= 0.55 {
            poseIndex = burstCount % 5
            burstCount += 1
        }
        alternate.toggle()
        lastKey = time
        deadline = time + 0.18
        return alternate
    }
    func active(at time: TimeInterval) -> Bool { phase(at: time) == .typing }
    func phase(at time: TimeInterval) -> ReactionPhase {
        guard let lastKey else { return .idle }
        if time < deadline { return .typing }
        if time >= lastKey + 0.55 && time < lastKey + 2.15 { return .pose(poseIndex) }
        return .idle
    }
    mutating func reset() { lastKey = nil; deadline = 0 }
}
struct Preferences: Codable {
    var size: Double = 180
    var x: Double? = nil
    var y: Double? = nil
    var selected: UUID? = nil
    var locked = false
    var topmost = true
    var characters: [Character] = []
}
final class Store {
    let root: URL
    var preferences: Preferences
    init() {
        root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("TypingPet", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let data = try? Data(contentsOf: root.appendingPathComponent("settings.json"))
        preferences = data.flatMap { try? JSONDecoder().decode(Preferences.self, from: $0) } ?? Preferences()
        preferences.size = min(480, max(80, preferences.size))

    }
    func save() throws {
        try JSONEncoder().encode(preferences).write(to: root.appendingPathComponent("settings.json"), options: .atomic)
    }
}

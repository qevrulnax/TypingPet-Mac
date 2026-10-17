// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "TypingPet", platforms: [.macOS(.v13)], products: [.executable(name: "TypingPet", targets: ["TypingPet"])], targets: [.executableTarget(name: "TypingPet"), .testTarget(name: "TypingPetTests", dependencies: ["TypingPet"])])

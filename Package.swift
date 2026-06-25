// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacroMouse",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MacroMouse",
            path: "Sources/MacroMouse",
            swiftSettings: [
                .unsafeFlags(["-framework", "Carbon"], .when(configuration: .release)),
                .unsafeFlags(["-framework", "Carbon"], .when(configuration: .debug)),
            ]
        )
    ]
)

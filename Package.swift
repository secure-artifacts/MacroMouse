// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacroMouse",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "MacroMouse",
            path: "Sources/MacroMouse",
            // Carbon 是系统框架，通过 linkerSettings 链接比 unsafeFlags 更干净，
            // 不会产生"unsafeFlags cannot be used for non-root targets"警告
            linkerSettings: [
                .linkedFramework("Carbon")
            ]
        )
    ]
)

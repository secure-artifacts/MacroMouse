import Foundation

/// 全局配置，通过 UserDefaults 持久化
class Config {
    static let shared = Config()
    private init() {}

    private let defaults = UserDefaults.standard

    private enum Key {
        static let textFilePath   = "textFilePath"
        static let minimumDist    = "minimumDistance"
        static let gestureEnabled = "gestureEnabled"
    }

    // MARK: - 文本文件路径
    // 修复：NSHomeDirectory() 在 .app 打包后可能返回沙盒路径。
    // 改用 FileManager.default.homeDirectoryForCurrentUser，
    // 它始终返回真实用户目录（/Users/你的用户名），不受沙盒影响。
    var textFilePath: String {
        get {
            defaults.string(forKey: Key.textFilePath)
                ?? (FileManager.default.homeDirectoryForCurrentUser.path + "/Desktop/MacroMouse.txt")
        }
        set { defaults.set(newValue, forKey: Key.textFilePath) }
    }

    // MARK: - 最小滑动距离（像素）
    var minimumDistance: CGFloat {
        get {
            let v = defaults.double(forKey: Key.minimumDist)
            return v > 0 ? CGFloat(v) : 40.0
        }
        set { defaults.set(Double(newValue), forKey: Key.minimumDist) }
    }

    // MARK: - 是否启用手势
    var gestureEnabled: Bool {
        get {
            if defaults.object(forKey: Key.gestureEnabled) == nil { return true }
            return defaults.bool(forKey: Key.gestureEnabled)
        }
        set { defaults.set(newValue, forKey: Key.gestureEnabled) }
    }
}

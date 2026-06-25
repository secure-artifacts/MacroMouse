import Cocoa
import UserNotifications
import Carbon.HIToolbox

/// 所有手势对应的执行逻辑
enum ActionExecutor {

    // MARK: - 复制（⌘C）
    static func performCopy() {
        postKeyboardShortcut(keyCode: kVK_ANSI_C, flags: .maskCommand)
    }

    // MARK: - 粘贴（⌘V）
    static func performPaste() {
        postKeyboardShortcut(keyCode: kVK_ANSI_V, flags: .maskCommand)
    }

    // MARK: - 剪切（⌘X）
    static func performCut() {
        postKeyboardShortcut(keyCode: kVK_ANSI_X, flags: .maskCommand)
    }

    // MARK: - 随机从文本文件读取一行，写入剪贴板并粘贴
    static func pasteRandomLine() {
        let path = Config.shared.textFilePath
        print("📂 文本文件路径：\(path)")

        guard FileManager.default.fileExists(atPath: path) else {
            print("❌ 文件不存在：\(path)")
            // 用 NSAlert 直接弹窗，不依赖通知权限
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "找不到文本文件"
                alert.informativeText = "路径：\(path)\n\n请打开菜单栏图标 → 偏好设置，设置正确的文件路径并保存。"
                alert.runModal()
            }
            return
        }

        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content
                .components(separatedBy: .newlines)
                .map    { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            print("📄 读到 \(lines.count) 行：\(lines)")

            guard !lines.isEmpty else {
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "文件为空"
                    alert.informativeText = "文本文件中没有可用内容，请添加一些行。"
                    alert.runModal()
                }
                return
            }

            let randomLine = lines.randomElement()!
            print("📝 随机选中：\(randomLine)")

            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(randomLine, forType: .string)
            postKeyboardShortcut(keyCode: kVK_ANSI_V, flags: .maskCommand)

        } catch {
            print("❌ 读取失败：\(error)")
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "读取文件失败"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }
    }

    // MARK: - 模拟键盘快捷键（底层 CGEvent）
    static func postKeyboardShortcut(keyCode: Int, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .combinedSessionState)
        let vk = CGKeyCode(UInt16(keyCode))

        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vk, keyDown: true),
            let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: vk, keyDown: false)
        else { return }

        keyDown.flags = flags
        keyUp.flags   = flags

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    // MARK: - 系统通知
    static func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("通知发送失败：\(error)") }
        }
    }

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error { print("通知权限请求失败：\(error)") }
            if !granted  { print("⚠️ 用户未授权通知") }
        }
    }
}

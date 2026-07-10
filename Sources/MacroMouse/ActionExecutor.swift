import Cocoa
import UserNotifications
import Carbon.HIToolbox

/// 所有手势对应的执行逻辑
enum ActionExecutor {

    // MARK: - 基础编辑
    static func performCopy()  { postKeyboardShortcut(keyCode: kVK_ANSI_C, flags: .maskCommand) }
    static func performPaste() { postKeyboardShortcut(keyCode: kVK_ANSI_V, flags: .maskCommand) }
    static func performCut()   { postKeyboardShortcut(keyCode: kVK_ANSI_X, flags: .maskCommand) }

    // MARK: - 回车（危险操作，仅由「右键快速双击」触发）
    static func performEnter() { postKeyboardShortcut(keyCode: kVK_Return, flags: []) }

    // MARK: - 随机文本粘贴
    static func pasteRandomLine() {
        let path = Config.shared.textFilePath
        print("📂 文本文件路径：\(path)")

        guard FileManager.default.fileExists(atPath: path) else {
            print("❌ 文件不存在：\(path)")
            DispatchQueue.main.async {
                let a = NSAlert()
                a.messageText     = "找不到文本文件"
                a.informativeText = "路径：\(path)\n\n请打开菜单栏图标 → 偏好设置，设置正确的文件路径并保存。"
                a.runModal()
            }
            return
        }

        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content
                .components(separatedBy: .newlines)
                .map    { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }   // 空行和 # 开头的注释行都不参与随机抽取

            print("📄 读到 \(lines.count) 行：\(lines)")

            guard !lines.isEmpty else {
                DispatchQueue.main.async {
                    let a = NSAlert()
                    a.messageText     = "文件为空"
                    a.informativeText = "文本文件中没有可用内容，请添加一些行。"
                    a.runModal()
                }
                return
            }

            let line = lines.randomElement()!
            print("📝 随机选中：\(line)")

            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(line, forType: .string)
            postKeyboardShortcut(keyCode: kVK_ANSI_V, flags: .maskCommand)

        } catch {
            print("❌ 读取失败：\(error)")
            DispatchQueue.main.async {
                let a = NSAlert()
                a.messageText     = "读取文件失败"
                a.informativeText = error.localizedDescription
                a.runModal()
            }
        }
    }

    // MARK: - 最小化当前窗口（⌘M）
    static func minimizeWindow() {
        postKeyboardShortcut(keyCode: kVK_ANSI_M, flags: .maskCommand)
    }

    // MARK: - 最大化（全屏切换）当前窗口
    //
    // macOS 没有统一最大化快捷键，用 AppleScript + AXFullScreen 属性实现。
    // 修复：放到后台线程执行，避免 AppleScript 的 IPC 延迟阻塞主线程。
    // CGEvent 键盘模拟必须在主线程；AppleScript 可以在任意线程。
    //
    static func maximizeWindow() {
        DispatchQueue.global(qos: .userInteractive).async {
            let script = """
            tell application "System Events"
                set frontApp to first application process whose frontmost is true
                tell frontApp
                    if exists window 1 then
                        set isFullScreen to value of attribute "AXFullScreen" of window 1
                        set value of attribute "AXFullScreen" of window 1 to not isFullScreen
                    end if
                end tell
            end tell
            """
            runAppleScript(script, errorTitle: "最大化失败")
        }
    }

    // MARK: - AppleScript 执行（内部工具，可在任意线程调用）
    private static func runAppleScript(_ source: String, errorTitle: String) {
        guard let script = NSAppleScript(source: source) else { return }
        var errorDict: NSDictionary?
        script.executeAndReturnError(&errorDict)
        if let err = errorDict {
            print("⚠️ AppleScript 错误（\(errorTitle)）：\(err)")
        }
    }

    // MARK: - 模拟键盘快捷键（底层 CGEvent，主线程调用）
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
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req) { if let e = $0 { print("通知失败：\(e)") } }
    }

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error { print("通知权限请求失败：\(error)") }
            if !granted  { print("⚠️ 用户未授权通知") }
        }
    }
}
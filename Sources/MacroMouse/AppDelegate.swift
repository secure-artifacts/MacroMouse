import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var gestureManager: GestureManager!
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 通知权限（原版缺少这一步，导致通知静默失败）
        ActionExecutor.requestNotificationPermission()

        setupMenuBar()

        gestureManager = GestureManager()
        gestureManager.startMonitoring()
        print("✅ MacroMouse 已启动")
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Bug 修复：退出时主动停止监听，释放全局 monitor token，
        // 防止进程退出后 token 泄漏到系统（小概率但规范写法）
        gestureManager.stopMonitoring()
    }

    // MARK: - 菜单栏图标
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cursorarrow.motionlines",
                                   accessibilityDescription: "MacroMouse")
            button.toolTip = "MacroMouse - 鼠标手势"
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "MacroMouse 运行中 ✓", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "偏好设置…",
                                action: #selector(openSettings),
                                keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "在访达中打开文本文件",
                                action: #selector(openTextFile),
                                keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))

        // Bug 修复：菜单项的 target 必须显式设置，
        // 否则在某些 macOS 版本上 action 找不到 responder 而静默失效
        for item in menu.items {
            if item.action == #selector(openSettings) ||
               item.action == #selector(openTextFile) {
                item.target = self
            }
        }

        statusItem.menu = menu
    }

    @objc private func openSettings() {
        // Bug 修复：窗口关闭后 controller 不置 nil，
        // 下次打开直接 showWindow 而不重建，保留用户上次填写的内容
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openTextFile() {
        let path = Config.shared.textFilePath
        if FileManager.default.fileExists(atPath: path) {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        } else {
            let alert = NSAlert()
            alert.messageText = "文本文件不存在"
            alert.informativeText = "路径：\(path)\n\n请前往偏好设置修改路径，或点击「创建示例文件」。"
            alert.runModal()
        }
    }
}

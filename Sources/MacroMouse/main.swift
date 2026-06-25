import Cocoa

// 请求辅助功能权限（全局事件监听必须）
func requestAccessibilityPermission() {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
    let trusted = AXIsProcessTrustedWithOptions(options)
    if !trusted {
        print("⚠️  请在「系统设置 → 隐私与安全 → 辅助功能」中授权本应用")
    }
}

requestAccessibilityPermission()

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // 不在 Dock 显示，只在菜单栏
app.run()

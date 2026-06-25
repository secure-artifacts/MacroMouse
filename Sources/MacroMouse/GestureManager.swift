import Cocoa
import Carbon

// MARK: - 手势方向
enum GestureDirection {
    case up, down, left, right
}

// MARK: - 核心手势管理器
class GestureManager {
    private var startPoint: NSPoint?
    private var isTracking = false

    private var mouseDownMonitor: Any?
    private var mouseUpMonitor: Any?

    func startMonitoring() {
        mouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown) { [weak self] _ in
            guard let self, Config.shared.gestureEnabled else { return }
            self.startPoint = NSEvent.mouseLocation
            self.isTracking = true
        }

        mouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .rightMouseUp) { [weak self] _ in
            guard let self, self.isTracking, let start = self.startPoint else { return }
            self.isTracking = false
            self.startPoint = nil
            let end = NSEvent.mouseLocation
            self.handleGesture(from: start, to: end)
        }
    }

    func stopMonitoring() {
        if let m = mouseDownMonitor { NSEvent.removeMonitor(m); mouseDownMonitor = nil }
        if let m = mouseUpMonitor   { NSEvent.removeMonitor(m); mouseUpMonitor   = nil }
    }

    // MARK: - 手势识别
    private func handleGesture(from start: NSPoint, to end: NSPoint) {
        let dx = end.x - start.x
        let dy = end.y - start.y  // macOS Y 轴向上：上滑 dy > 0

        let dist = max(abs(dx), abs(dy))
        guard dist >= Config.shared.minimumDistance else { return }

        let direction: GestureDirection
        if abs(dx) > abs(dy) {
            direction = dx > 0 ? .right : .left
        } else {
            direction = dy > 0 ? .up : .down
        }

        dispatchAction(for: direction)
    }

    // MARK: - 动作派发
    //
    // 延迟策略说明：
    //   右键松开后，系统会弹出右键菜单（约需 50-80ms 完成绘制）。
    //   对于只需模拟快捷键的动作（复制/粘贴/剪切），
    //   等菜单弹出后焦点仍在原应用，快捷键能正确送达。
    //   对于需要额外操作剪贴板的动作（右滑随机文本），
    //   不在这里再加延迟，由 pasteRandomLine 内部统一控制。
    //
    private func dispatchAction(for direction: GestureDirection) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            switch direction {
            case .up:
                print("🖱 手势：上 → 复制")
                ActionExecutor.performCopy()
            case .down:
                print("🖱 手势：下 → 粘贴")
                ActionExecutor.performPaste()
            case .right:
                print("🖱 手势：右 → 随机文本输入")
                ActionExecutor.pasteRandomLine()
            case .left:
                print("🖱 手势：左 → 剪切")
                ActionExecutor.performCut()
            }
        }
    }
}

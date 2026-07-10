import Cocoa
import Carbon

// MARK: - 手势方向（8向）
enum GestureDirection {
    case up, down, left, right
    case upRight, upLeft, downRight, downLeft
}

// MARK: - 核心手势管理器
class GestureManager {
    private var startPoint: NSPoint?
    private var isTracking = false

    private var mouseDownMonitor: Any?
    private var mouseUpMonitor: Any?

    // MARK: - 右键快速双击 → 回车（危险操作，需严格限制误触发）
    //
    // 只有当两次右键"点击"（几乎无移动）发生在系统双击时间间隔内、
    // 且两次点击位置足够接近时，才判定为快速双击。
    // 单次点击、拖动手势、或超时的第二次点击都不会触发。
    //
    private var lastRightClickTime: Date?
    private var lastRightClickPoint: NSPoint?
    private let clickMoveTolerance: CGFloat = 8   // 小于此距离视为"点击"而非拖动手势

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

            let dx = end.x - start.x
            let dy = end.y - start.y
            let moveDist = max(abs(dx), abs(dy))

            if moveDist < self.clickMoveTolerance {
                // 几乎没有移动 → 这是一次"点击"而非手势，交给双击检测
                self.handlePotentialDoubleClick(at: end)
            } else {
                self.handleGesture(from: start, to: end)
            }
        }
    }

    func stopMonitoring() {
        if let m = mouseDownMonitor { NSEvent.removeMonitor(m); mouseDownMonitor = nil }
        if let m = mouseUpMonitor   { NSEvent.removeMonitor(m); mouseUpMonitor   = nil }
    }

    // MARK: - 手势识别（8向）
    //
    // 判断策略：
    //   先看总距离是否够长（minimumDistance）。
    //   再看 dx/dy 的比例：
    //     比例在 0.4 ~ 2.5 之间 → 斜向（45° ± ~22°）
    //     比例 <= 0.4           → 纯垂直（上/下）
    //     比例 >= 2.5           → 纯水平（左/右）
    //   斜向阈值 0.4/2.5 对应约 22°，手感自然，
    //   不会因为轻微歪斜把斜向误判为直向。
    //
    private func handleGesture(from start: NSPoint, to end: NSPoint) {
        let dx   = end.x - start.x
        let dy   = end.y - start.y   // macOS Y 轴向上：上滑 dy > 0
        let dist = max(abs(dx), abs(dy))

        guard dist >= Config.shared.minimumDistance else { return }

        let direction: GestureDirection
        let ratio = abs(dx) / max(abs(dy), 1)   // 防止除零

        if ratio >= 0.4 && ratio <= 2.5 {
            // 斜向
            switch (dx > 0, dy > 0) {
            case (true,  true):  direction = .upRight
            case (false, true):  direction = .upLeft
            case (true,  false): direction = .downRight
            case (false, false): direction = .downLeft
            }
        } else if abs(dx) > abs(dy) {
            // 水平
            direction = dx > 0 ? .right : .left
        } else {
            // 垂直
            direction = dy > 0 ? .up : .down
        }

        dispatchAction(for: direction)
    }

    // MARK: - 右键快速双击检测
    private func handlePotentialDoubleClick(at point: NSPoint) {
        let now = Date()

        defer {
            // 无论本次是否判定成功，都把这次点击记为"上一次点击"，
            // 供下一次点击比对（同时也防止连续三击被误判为两次双击）
            lastRightClickTime  = now
            lastRightClickPoint = point
        }

        guard
            let lastTime  = lastRightClickTime,
            let lastPoint = lastRightClickPoint
        else { return }   // 这是第一次点击，先记录，等待可能的第二次

        let interval = now.timeIntervalSince(lastTime)
        let dx = point.x - lastPoint.x
        let dy = point.y - lastPoint.y
        let posDist = max(abs(dx), abs(dy))

        guard interval <= NSEvent.doubleClickInterval, posDist < clickMoveTolerance else {
            return   // 太慢或位置偏移太大，不算快速双击
        }

        // 判定为快速双击：清空状态，避免紧接着的第三次点击被误判
        lastRightClickTime  = nil
        lastRightClickPoint = nil

        print("🖱 右键快速双击 → 回车（危险操作，已确认为快速双击）")
        // 与手势动作保持一致的延迟，等右键菜单绘制完成、焦点稳定后再发送
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            ActionExecutor.performEnter()
        }
    }

    // MARK: - 动作派发
    //
    // 延迟 80ms：等右键菜单完成绘制，焦点稳定在原应用后再发快捷键。
    // pasteRandomLine 不在内部再加延迟，统一由这里的 80ms 覆盖。
    //
    private func dispatchAction(for direction: GestureDirection) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            switch direction {
            case .up:        print("🖱 上       → 复制");          ActionExecutor.performCopy()
            case .down:      print("🖱 下       → 粘贴");          ActionExecutor.performPaste()
            case .right:     print("🖱 右       → 随机文本");      ActionExecutor.pasteRandomLine()
            case .left:      print("🖱 左       → 剪切");          ActionExecutor.performCut()
            case .upRight:   print("🖱 右上     → 最大化窗口");    ActionExecutor.maximizeWindow()
            case .downLeft:  print("🖱 左下     → 最小化窗口");    ActionExecutor.minimizeWindow()
            case .upLeft:    print("🖱 左上     → (未分配)");      break
            case .downRight: print("🖱 右下     → (未分配)");      break
            }
        }
    }
}
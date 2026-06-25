import Cocoa

class SettingsWindowController: NSWindowController {

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 380),
            styleMask:   [.titled, .closable],
            backing:     .buffered,
            defer:       false
        )
        window.title = "MacroMouse 偏好设置"
        window.center()
        self.init(window: window)
        window.contentViewController = SettingsViewController()
    }
}

class SettingsViewController: NSViewController {

    private let pathField    = NSTextField()
    private let browseButton = NSButton(title: "浏览…", target: nil, action: nil)
    private let distSlider   = NSSlider()
    private let distLabel    = NSTextField(labelWithString: "")
    private let enableToggle = NSButton(checkboxWithTitle: "启用鼠标手势", target: nil, action: nil)
    private let helpLabel    = NSTextField(wrappingLabelWithString: "")

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 380))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSettings()
    }

    // MARK: - 布局
    private func setupUI() {
        let title = NSTextField(labelWithString: "MacroMouse 设置")
        title.font = .boldSystemFont(ofSize: 18)
        title.frame = NSRect(x: 20, y: 335, width: 300, height: 30)
        view.addSubview(title)

        // 4向说明
        let desc4 = NSTextField(wrappingLabelWithString:
            "↑ 上滑 → 复制   |   ↓ 下滑 → 粘贴   |   → 右滑 → 随机文本   |   ← 左滑 → 剪切")
        desc4.font = .systemFont(ofSize: 11)
        desc4.textColor = .secondaryLabelColor
        desc4.frame = NSRect(x: 20, y: 308, width: 480, height: 20)
        view.addSubview(desc4)

        // 斜向说明
        let desc8 = NSTextField(wrappingLabelWithString:
            "↗ 右上滑 → 最大化/全屏切换   |   ↙ 左下滑 → 最小化   |   ↖ 左上滑 / ↘ 右下滑 → 未分配")
        desc8.font = .systemFont(ofSize: 11)
        desc8.textColor = .secondaryLabelColor
        desc8.frame = NSRect(x: 20, y: 286, width: 480, height: 20)
        view.addSubview(desc8)

        let sep1 = NSBox(); sep1.boxType = .separator
        sep1.frame = NSRect(x: 20, y: 276, width: 480, height: 1)
        view.addSubview(sep1)

        // 启用开关
        enableToggle.frame = NSRect(x: 20, y: 248, width: 200, height: 20)
        enableToggle.target = self
        enableToggle.action = #selector(toggleChanged)
        view.addSubview(enableToggle)

        // 最小滑动距离
        let distTitle = NSTextField(labelWithString: "最小触发距离（像素）")
        distTitle.frame = NSRect(x: 20, y: 212, width: 200, height: 20)
        view.addSubview(distTitle)

        distSlider.frame = NSRect(x: 20, y: 188, width: 400, height: 24)
        distSlider.minValue = 10
        distSlider.maxValue = 120
        distSlider.numberOfTickMarks = 12
        distSlider.allowsTickMarkValuesOnly = false
        distSlider.target = self
        distSlider.action = #selector(sliderChanged)
        view.addSubview(distSlider)

        distLabel.frame = NSRect(x: 430, y: 188, width: 70, height: 24)
        distLabel.alignment = .right
        view.addSubview(distLabel)

        // 文本文件路径
        let pathTitle = NSTextField(labelWithString: "随机文本文件路径（右滑手势使用）")
        pathTitle.frame = NSRect(x: 20, y: 150, width: 300, height: 20)
        view.addSubview(pathTitle)

        pathField.frame = NSRect(x: 20, y: 124, width: 400, height: 24)
        pathField.placeholderString = FileManager.default.homeDirectoryForCurrentUser.path + "/Desktop/MacroMouse.txt"
        view.addSubview(pathField)

        browseButton.frame = NSRect(x: 430, y: 122, width: 70, height: 28)
        browseButton.target = self
        browseButton.action = #selector(browse)
        view.addSubview(browseButton)

        helpLabel.font = .systemFont(ofSize: 11)
        helpLabel.textColor = .secondaryLabelColor
        helpLabel.frame = NSRect(x: 20, y: 88, width: 480, height: 30)
        view.addSubview(helpLabel)

        let sep2 = NSBox(); sep2.boxType = .separator
        sep2.frame = NSRect(x: 20, y: 78, width: 480, height: 1)
        view.addSubview(sep2)

        let saveBtn = NSButton(title: "保存", target: self, action: #selector(save))
        saveBtn.frame = NSRect(x: 420, y: 44, width: 80, height: 28)
        saveBtn.bezelStyle = .rounded
        saveBtn.keyEquivalent = "\r"
        view.addSubview(saveBtn)

        let createBtn = NSButton(title: "创建示例文件", target: self, action: #selector(createSample))
        createBtn.frame = NSRect(x: 20, y: 44, width: 130, height: 28)
        createBtn.bezelStyle = .rounded
        view.addSubview(createBtn)

        // 版本号
        let ver = NSTextField(labelWithString: "v1.0.5")
        ver.font = .systemFont(ofSize: 10)
        ver.textColor = .tertiaryLabelColor
        ver.frame = NSRect(x: 20, y: 14, width: 100, height: 16)
        view.addSubview(ver)
    }

    // MARK: - 读取设置
    private func loadSettings() {
        pathField.stringValue  = Config.shared.textFilePath
        distSlider.doubleValue = Double(Config.shared.minimumDistance)
        enableToggle.state     = Config.shared.gestureEnabled ? .on : .off
        updateDistLabel()
        updateHelpLabel()
    }

    @objc private func sliderChanged() { updateDistLabel() }

    @objc private func toggleChanged() {
        Config.shared.gestureEnabled = (enableToggle.state == .on)
    }

    @objc private func browse() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes  = [.plainText]
        panel.canChooseDirectories = false
        panel.canChooseFiles       = true
        if panel.runModal() == .OK, let url = panel.url {
            pathField.stringValue = url.path
            updateHelpLabel()
        }
    }

    @objc private func save() {
        let path = pathField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !path.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "路径不能为空"
            alert.informativeText = "请输入或选择文本文件路径。"
            alert.runModal()
            return
        }
        Config.shared.textFilePath    = path
        Config.shared.minimumDistance = CGFloat(distSlider.doubleValue)
        Config.shared.gestureEnabled  = (enableToggle.state == .on)
        updateHelpLabel()
        let alert = NSAlert()
        alert.messageText     = "已保存"
        alert.informativeText = "设置已更新，即时生效。"
        alert.runModal()
    }

    @objc private func createSample() {
        let path = pathField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !path.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "请先填写文件路径"
            alert.runModal()
            return
        }
        let sample = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"].joined(separator: "\n")
        do {
            let dir = (path as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try sample.write(toFile: path, atomically: true, encoding: .utf8)
            updateHelpLabel()
            let alert = NSAlert()
            alert.messageText     = "示例文件已创建"
            alert.informativeText = "路径：\(path)"
            alert.runModal()
        } catch {
            let alert = NSAlert()
            alert.messageText     = "创建失败"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private func updateDistLabel() { distLabel.stringValue = "\(Int(distSlider.doubleValue)) px" }

    private func updateHelpLabel() {
        let path   = pathField.stringValue.trimmingCharacters(in: .whitespaces)
        let exists = !path.isEmpty && FileManager.default.fileExists(atPath: path)
        helpLabel.stringValue = exists
            ? "✅ 文件存在，右滑手势将从此文件随机抽取一行"
            : "⚠️  文件不存在，请修改路径或点击「创建示例文件」"
    }
}

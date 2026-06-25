import Cocoa

class SettingsWindowController: NSWindowController {

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 340),
            styleMask:   [.titled, .closable],
            backing:     .buffered,
            defer:       false
        )
        window.title = "MacroMouse 偏好设置"
        window.center()
        // Bug 修复：必须先 init(window:) 再设 contentViewController，
        // 否则 window 持有 vc 之前 vc 可能被释放
        self.init(window: window)
        window.contentViewController = SettingsViewController()
    }
}

class SettingsViewController: NSViewController {

    // UI 控件（声明时不绑 target/action，避免 self 在 init 前被捕获）
    private let pathField    = NSTextField()
    private let browseButton = NSButton(title: "浏览…", target: nil, action: nil)
    private let distSlider   = NSSlider()
    private let distLabel    = NSTextField(labelWithString: "")
    private let enableToggle = NSButton(checkboxWithTitle: "启用鼠标手势", target: nil, action: nil)
    private let helpLabel    = NSTextField(wrappingLabelWithString: "")

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 480, height: 340))
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
        title.frame = NSRect(x: 20, y: 290, width: 300, height: 30)
        view.addSubview(title)

        let desc = NSTextField(wrappingLabelWithString:
            "右键上滑 → 复制   |   右键下滑 → 粘贴   |   右键右滑 → 随机文本   |   右键左滑 → 剪切")
        desc.font = .systemFont(ofSize: 11)
        desc.textColor = .secondaryLabelColor
        desc.frame = NSRect(x: 20, y: 258, width: 440, height: 30)
        view.addSubview(desc)

        let sep1 = NSBox(); sep1.boxType = .separator
        sep1.frame = NSRect(x: 20, y: 248, width: 440, height: 1)
        view.addSubview(sep1)

        // 启用开关
        enableToggle.frame = NSRect(x: 20, y: 218, width: 200, height: 20)
        enableToggle.target = self
        enableToggle.action = #selector(toggleChanged)
        view.addSubview(enableToggle)

        // 最小滑动距离
        let distTitle = NSTextField(labelWithString: "最小触发距离（像素）")
        distTitle.frame = NSRect(x: 20, y: 182, width: 200, height: 20)
        view.addSubview(distTitle)

        distSlider.frame = NSRect(x: 20, y: 158, width: 360, height: 24)
        distSlider.minValue = 10
        distSlider.maxValue = 120
        distSlider.numberOfTickMarks = 12
        distSlider.allowsTickMarkValuesOnly = false
        distSlider.target = self
        distSlider.action = #selector(sliderChanged)
        view.addSubview(distSlider)

        distLabel.frame = NSRect(x: 390, y: 158, width: 70, height: 24)
        distLabel.alignment = .right
        view.addSubview(distLabel)

        // 文本文件路径
        let pathTitle = NSTextField(labelWithString: "随机文本文件路径")
        pathTitle.frame = NSRect(x: 20, y: 118, width: 200, height: 20)
        view.addSubview(pathTitle)

        pathField.frame = NSRect(x: 20, y: 92, width: 360, height: 24)
        pathField.placeholderString = FileManager.default.homeDirectoryForCurrentUser.path + "/Desktop/MacroMouse.txt"
        view.addSubview(pathField)

        browseButton.frame = NSRect(x: 390, y: 90, width: 70, height: 28)
        browseButton.target = self
        browseButton.action = #selector(browse)
        view.addSubview(browseButton)

        helpLabel.font = .systemFont(ofSize: 11)
        helpLabel.textColor = .secondaryLabelColor
        helpLabel.frame = NSRect(x: 20, y: 58, width: 440, height: 30)
        view.addSubview(helpLabel)

        let sep2 = NSBox(); sep2.boxType = .separator
        sep2.frame = NSRect(x: 20, y: 48, width: 440, height: 1)
        view.addSubview(sep2)

        let saveBtn = NSButton(title: "保存", target: self, action: #selector(save))
        saveBtn.frame = NSRect(x: 380, y: 14, width: 80, height: 28)
        saveBtn.bezelStyle = .rounded
        saveBtn.keyEquivalent = "\r"
        view.addSubview(saveBtn)

        let createBtn = NSButton(title: "创建示例文件", target: self, action: #selector(createSample))
        createBtn.frame = NSRect(x: 20, y: 14, width: 130, height: 28)
        createBtn.bezelStyle = .rounded
        view.addSubview(createBtn)
    }

    // MARK: - 读取设置
    private func loadSettings() {
        pathField.stringValue  = Config.shared.textFilePath
        distSlider.doubleValue = Double(Config.shared.minimumDistance)
        enableToggle.state     = Config.shared.gestureEnabled ? .on : .off
        updateDistLabel()
        updateHelpLabel()
    }

    // MARK: - 操作响应
    @objc private func sliderChanged() {
        updateDistLabel()
    }

    // Bug 修复：原版 toggleChanged 是空方法，导致勾选后不保存也无反馈。
    // 现在即时写入 Config，不需要点保存也能切换手势开关。
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
        // Bug 修复：路径为空时不允许保存
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
        alert.messageText    = "已保存"
        alert.informativeText = "设置已更新，即时生效。"
        alert.runModal()
    }

    @objc private func createSample() {
        // 使用当前路径字段的值（而非已保存的 Config 值），
        // 这样用户先填路径再点创建，不必先保存一次
        let path = pathField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !path.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "请先填写文件路径"
            alert.runModal()
            return
        }

        let sample = [
            "这是第一行示例文本",
            "Hello, world!",
            "随机短语三号",
            "Swift is awesome",
            "今天天气真好",
            "MacroMouse 正在运行",
        ].joined(separator: "\n")

        do {
            // Bug 修复：如果父目录不存在先创建，否则 write 会抛错
            let dir = (path as NSString).deletingLastPathComponent
            try FileManager.default.createDirectory(
                atPath: dir,
                withIntermediateDirectories: true
            )
            try sample.write(toFile: path, atomically: true, encoding: .utf8)
            updateHelpLabel()
            let alert = NSAlert()
            alert.messageText    = "示例文件已创建"
            alert.informativeText = "路径：\(path)"
            alert.runModal()
        } catch {
            let alert = NSAlert()
            alert.messageText    = "创建失败"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private func updateDistLabel() {
        distLabel.stringValue = "\(Int(distSlider.doubleValue)) px"
    }

    private func updateHelpLabel() {
        let path   = pathField.stringValue.trimmingCharacters(in: .whitespaces)
        let exists = !path.isEmpty && FileManager.default.fileExists(atPath: path)
        helpLabel.stringValue = exists
            ? "✅ 文件存在，右滑手势将从此文件随机抽取一行"
            : "⚠️  文件不存在，请修改路径或点击「创建示例文件」"
    }
}

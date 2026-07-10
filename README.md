# MacroMouse

一个轻量的 macOS 菜单栏鼠标手势工具：按住鼠标右键滑动，即可触发复制/粘贴/剪切、随机文本粘贴、窗口最大化/最小化等操作。

![Gesture Diagram](assets/gesture-diagram.svg)

## ✨ 功能

| 手势 | 动作 |
| --- | --- |
| ↑ 上滑 | 复制（⌘C） |
| ↓ 下滑 | 粘贴（⌘V） |
| → 右滑 | 从指定文本文件中随机粘贴一行 |
| ← 左滑 | 剪切（⌘X） |
| ↗ 右上滑 | 最大化 / 全屏切换 |
| ↙ 左下滑 | 最小化窗口（⌘M） |
| ↖ 左上滑 / ↘ 右下滑 | 未分配，预留扩展 |
| ⚡ 右键快速双击（不拖动） | 回车（危险操作，见下方说明） |

### 关于「右键快速双击 → 回车」

回车是一个有风险的操作（可能确认删除、提交表单等），因此触发条件比普通手势更严格：

- 两次右键点击之间**几乎没有移动**（视为点击而非拖动手势）
- 两次点击的**时间间隔在系统双击间隔内**（跟随 macOS 系统设置，不是写死的固定值）
- 两次点击的**位置足够接近**

单次点击、慢速的两次点击、或点击后拖动都不会触发，避免误触发。

## 🚀 安装 / 构建

### 直接下载

- **正式版本**：在 [Releases](https://github.com/secure-artifacts/MacroMouse/releases) 页面下载。每次打 `v*` tag（如 `v1.1.0`）会自动触发构建并发布到对应 Release，文件名形如：
  - `MacroMouse-macOS-v1.1.0.zip`（Apple Silicon）
  - `Mouse-intel-v1.1.0.zip`（Intel）
- **开发版本**：push 到 `main` 分支或提交 PR 也会自动构建，但不会发布到 Release，只能在对应 [Actions](https://github.com/secure-artifacts/MacroMouse/actions) 运行记录的 Artifacts 里下载（保留 7 天），文件名带 `dev` 版本号，如 `MacroMouse-macOS-dev.zip`。
- 打 tag 触发的构建还会附加 [build provenance attestation](https://github.com/secure-artifacts/MacroMouse/attestations)，可用于验证产物确实来自本仓库的 CI。

首次打开若提示"无法验证开发者"，右键点击 App →「打开」，或在「系统设置 → 隐私与安全性」中允许运行（应用为 ad-hoc 签名，非公证发布）。

### 本地构建

需要 Xcode / Swift 工具链（`swift build` 可用即可）。

```bash
git clone https://github.com/secure-artifacts/MacroMouse.git
cd MacroMouse

# Apple Silicon
./build.sh arm64

# Intel
./build.sh x86_64
```

构建完成后会在 `dist/` 目录生成 `MacroMouse.app` 及对应的 `MacroMouse-macOS.zip` / `MacroMouse-Intel.zip`。`build.sh` 会自动完成编译（`swift build -c release`）、打包 `.app`、拷贝 `Resources/Info.plist`（及 `AppIcon.icns`，如存在）、ad-hoc 代码签名。

也可以只编译不打包：

```bash
swift build -c release
swift run
```

首次运行需要在 **系统设置 → 隐私与安全性 → 辅助功能** 中为 MacroMouse 授权（用于监听全局鼠标事件和模拟键盘按键）。

## ⚙️ 使用

1. 启动后应用会出现在菜单栏（无 Dock 图标）。
2. 点击菜单栏图标 →「偏好设置」，可以：
   - 开启/关闭手势
   - 调整最小触发距离
   - 设置随机文本文件路径，并一键生成示例文件
3. 按住鼠标右键并滑动即可触发对应动作。

## 📁 项目结构

```
MacroMouse/
├── Sources/MacroMouse/
│   ├── main.swift                    # 入口，请求辅助功能权限
│   ├── AppDelegate.swift             # 菜单栏图标与生命周期
│   ├── GestureManager.swift          # 手势 / 双击识别核心逻辑
│   ├── ActionExecutor.swift          # 具体动作执行（键盘模拟、AppleScript 等）
│   ├── Config.swift                  # 基于 UserDefaults 的配置存储
│   └── SettingsViewController.swift  # 偏好设置界面
├── Resources/
│   └── Info.plist                    # 应用元数据与权限说明
├── .github/workflows/build.yml       # GitHub Actions 自动打包（arm64 + x86_64）
├── Package.swift                     # Swift Package Manager
├── build.sh                          # 本地/CI 打包脚本（编译 → 打包 .app → 签名 → 压缩）
└── assets/gesture-diagram.svg        # 手势示意图
```

## ⚠️ 注意事项

- 需要「辅助功能」权限才能监听全局鼠标事件和模拟按键。
- 应用不会拦截或消费鼠标事件，右键菜单仍会正常弹出。
- 最大化/全屏切换基于 AppleScript + Accessibility API 实现，个别应用（未适配无障碍接口）可能不响应。

## 📄 License

[MIT](LICENSE)
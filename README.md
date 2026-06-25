# 🖱 MacroMouse

一款轻量的 macOS 全局鼠标手势工具，无需安装，住在菜单栏。

---

## ✨ 功能

| 手势 | 动作 |
|------|------|
| 右键 **上滑** | 复制（⌘C） |
| 右键 **下滑** | 粘贴（⌘V） |
| 右键 **右滑** | 从文本文件随机抽取一行并粘贴 |
| 右键 **左滑** | 清空剪贴板 |

---

## 🚀 快速开始

### 方式一：直接下载（推荐）

前往 [Releases](../../releases) 下载最新的 `MacroMouse.app`，拖入 `/Applications` 即可。

### 方式二：从源码编译

**前提：** macOS 13+，Xcode 15 或 Command Line Tools

```bash
git clone https://github.com/yourname/MacroMouse.git
cd MacroMouse
chmod +x build.sh
./build.sh
```

编译产物在 `dist/MacroMouse.app`。

---

## ⚙️ 首次运行配置

1. **打开应用** — 菜单栏出现鼠标光标图标即为成功
2. **授权辅助功能** — 系统会弹窗提示，点击「打开系统设置」并勾选 MacroMouse

   > 路径：系统设置 → 隐私与安全性 → 辅助功能

3. **准备文本文件（可选）** — 菜单栏图标 → 偏好设置 → 创建示例文件

---

## 📂 项目结构

```
MacroMouse/
├── Sources/MacroMouse/
│   ├── main.swift                # 入口，请求辅助功能权限
│   ├── AppDelegate.swift         # 菜单栏生命周期
│   ├── GestureManager.swift      # 全局鼠标事件监听与手势识别
│   ├── ActionExecutor.swift      # 手势动作执行（复制/粘贴/随机文本/清空）
│   ├── SettingsViewController.swift  # 偏好设置窗口
│   └── Config.swift              # UserDefaults 配置持久化
├── Resources/
│   └── Info.plist                # 应用元数据与权限说明
├── .github/workflows/build.yml   # GitHub Actions 自动打包
├── Package.swift                 # Swift Package Manager
├── build.sh                      # 本地打包脚本
└── README.md
```

---

## 🗺 架构图

```
右键按下
    │
    ▼
GestureManager
  startPoint = 当前鼠标位置
    │
    │（右键松开）
    ▼
analyzeGesture(from:to:)
  dx = end.x - start.x
  dy = end.y - start.y
  方向 = max(|dx|, |dy|) 对应轴
    │
    ├── 上 ──▶ ActionExecutor.performCopy()
    ├── 下 ──▶ ActionExecutor.performPaste()
    ├── 右 ──▶ ActionExecutor.pasteRandomLine()
    └── 左 ──▶ ActionExecutor.clearClipboard()

Config（UserDefaults）
  ├── textFilePath        ← 随机文本文件路径
  ├── minimumDistance     ← 最小触发像素（默认 40px）
  └── gestureEnabled      ← 全局开关
```

---

## 🔒 隐私说明

- 本应用**不联网**，所有数据留在本机
- 监听鼠标事件需要辅助功能权限（macOS 强制要求）
- 不记录鼠标坐标或任何用户数据

---

## 🛠 扩展手势

在 `GestureManager.swift` 的 `dispatchAction` 中添加分支，在 `ActionExecutor.swift` 中添加对应方法即可。

---

## 📋 系统要求

- macOS 13 Ventura 或更新
- 辅助功能权限

---

## 📄 License

MIT

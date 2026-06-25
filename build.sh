#!/usr/bin/env bash
# build.sh — 编译 MacroMouse 并打包成 .app
set -e

APP_NAME="MacroMouse"
BUNDLE_ID="com.yourname.macromouse"
BUILD_DIR=".build/release"
APP_DIR="dist/${APP_NAME}.app"

echo "🔨 编译中（Release 模式）..."
swift build -c release 2>&1

echo "📦 打包 .app 结构..."
rm -rf dist && mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"

# 拷贝可执行文件
cp "${BUILD_DIR}/${APP_NAME}" "${APP_DIR}/Contents/MacOS/"

# 拷贝 Info.plist
cp "Resources/Info.plist" "${APP_DIR}/Contents/"

# 如果有图标
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${APP_DIR}/Contents/Resources/"
fi

echo ""
echo "✅ 打包完成！"
echo "   路径：$(pwd)/${APP_DIR}"
echo ""
echo "▶ 首次运行需要在「系统设置 → 隐私与安全 → 辅助功能」中授权 MacroMouse"
echo ""
echo "▶ 若要移动到 Applications："
echo "   cp -r dist/${APP_NAME}.app /Applications/"

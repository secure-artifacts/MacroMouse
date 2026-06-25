#!/usr/bin/env bash
# build.sh <arm64|x86_64> — 编译 MacroMouse 并打包成单一架构 .app
#
# 命名规则（重要）：
#   arm64   (M 系列芯片) → 打包文件名包含 "macOS"
#   x86_64  (Intel 芯片) → 打包文件名包含 "Intel"
set -e

ARCH="$1"
if [ -z "${ARCH}" ]; then
    echo "❌ 用法: ./build.sh <arm64|x86_64>"
    exit 1
fi

APP_NAME="MacroMouse"
BUNDLE_ID="com.yourname.macromouse"

case "${ARCH}" in
    arm64)
        LABEL="macOS"     # M 芯片版本
        ;;
    x86_64)
        LABEL="Intel"     # Intel 芯片版本
        ;;
    *)
        echo "❌ 不支持的架构: ${ARCH}（只支持 arm64 / x86_64）"
        exit 1
        ;;
esac

APP_DIR="dist/${APP_NAME}.app"
BIN_PATH=".build/${ARCH}-apple-macosx/release/${APP_NAME}"
ZIP_NAME="${APP_NAME}-${LABEL}.zip"

echo "🔨 编译 ${ARCH}（命名为 ${LABEL} 版本）..."
swift build -c release --arch "${ARCH}"

echo "📦 打包 .app 结构..."
rm -rf dist && mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"

if [ ! -f "${BIN_PATH}" ]; then
    echo "❌ 找不到可执行文件：${BIN_PATH}"
    echo "   请检查 Package.swift 里 executable target 的名字是否精确为 ${APP_NAME}"
    exit 1
fi

cp "${BIN_PATH}" "${APP_DIR}/Contents/MacOS/"

# 拷贝 Info.plist
cp "Resources/Info.plist" "${APP_DIR}/Contents/"

# 如果有图标
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${APP_DIR}/Contents/Resources/"
fi

echo "🔍 验证架构（应只显示单一架构 ${ARCH}）："
lipo -info "${APP_DIR}/Contents/MacOS/${APP_NAME}" 2>/dev/null || file "${APP_DIR}/Contents/MacOS/${APP_NAME}"

echo "🗜  压缩为 ${ZIP_NAME}..."
( cd dist && ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "${ZIP_NAME}" )

echo ""
echo "✅ 打包完成！（${LABEL} 版本）"
echo "   路径：$(pwd)/dist/${ZIP_NAME}"
echo ""
echo "▶ 首次运行需要在「系统设置 → 隐私与安全 → 辅助功能」中授权 MacroMouse"
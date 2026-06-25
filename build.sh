#!/usr/bin/env bash
# build.sh <arm64|x86_64> — 编译 MacroMouse 并打包成 .app
#
# 命名规则：
#   arm64   (M 系列芯片) → 文件名含 "macOS"
#   x86_64  (Intel 芯片) → 文件名含 "Intel"
set -e

VERSION="1.0.5"
ARCH="$1"

if [ -z "${ARCH}" ]; then
    echo "❌ 用法: ./build.sh <arm64|x86_64>"
    exit 1
fi

APP_NAME="MacroMouse"

case "${ARCH}" in
    arm64)  LABEL="macOS" ;;
    x86_64) LABEL="Intel" ;;
    *)
        echo "❌ 不支持的架构: ${ARCH}（只支持 arm64 / x86_64）"
        exit 1
        ;;
esac

APP_DIR="dist/${APP_NAME}.app"
BIN_PATH=".build/${ARCH}-apple-macosx/release/${APP_NAME}"
ZIP_NAME="${APP_NAME}-${VERSION}-${LABEL}.zip"

echo "🔨 编译 ${ARCH}（${LABEL} 版本，v${VERSION}）..."
swift build -c release --arch "${ARCH}"

echo "📦 打包 .app 结构..."
rm -rf dist && mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"

if [ ! -f "${BIN_PATH}" ]; then
    echo "❌ 找不到可执行文件：${BIN_PATH}"
    exit 1
fi

cp "${BIN_PATH}" "${APP_DIR}/Contents/MacOS/"
cp "Resources/Info.plist" "${APP_DIR}/Contents/"

if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${APP_DIR}/Contents/Resources/"
fi

echo "✍️  ad-hoc 签名..."
codesign --force --deep -s - "${APP_DIR}"

echo "🔍 验证架构："
lipo -info "${APP_DIR}/Contents/MacOS/${APP_NAME}" 2>/dev/null || file "${APP_DIR}/Contents/MacOS/${APP_NAME}"

echo "🗜  压缩为 ${ZIP_NAME}..."
( cd dist && ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "${ZIP_NAME}" )

echo ""
echo "✅ 打包完成！v${VERSION} ${LABEL} 版本"
echo "   路径：$(pwd)/dist/${ZIP_NAME}"
echo ""
echo "▶ 首次运行需要在「系统设置 → 隐私与安全性 → 辅助功能」中授权 MacroMouse"

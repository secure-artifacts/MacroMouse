#!/usr/bin/env bash
# build.sh <arm64|x86_64>
# 输出固定文件名（不含版本号），由 GitHub Actions workflow 负责重命名注入版本
set -e

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
        echo "❌ 不支持的架构: ${ARCH}"
        exit 1
        ;;
esac

APP_DIR="dist/${APP_NAME}.app"
BIN_PATH=".build/${ARCH}-apple-macosx/release/${APP_NAME}"
# 固定文件名，不含版本号，供 workflow Dynamic Rename 步骤使用
ZIP_NAME="${APP_NAME}-${LABEL}.zip"

echo "🔨 编译 ${ARCH}（${LABEL}）..."
swift build -c release --arch "${ARCH}"

echo "📦 打包 .app..."
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

echo "🗜  压缩为 ${ZIP_NAME}..."
( cd dist && ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "${ZIP_NAME}" )

echo "✅ 完成：dist/${ZIP_NAME}"
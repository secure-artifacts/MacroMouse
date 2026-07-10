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
# 兼容两种 SPM 构建产物布局：
#   传统布局：.build/<arch>-apple-macosx/release/<APP_NAME>
#   XCBuild 布局（较新 Xcode 工具链默认）：.build/out/Products/Release/<APP_NAME>
LEGACY_BIN_PATH=".build/${ARCH}-apple-macosx/release/${APP_NAME}"
XCBUILD_BIN_PATH=".build/out/Products/Release/${APP_NAME}"
# 固定文件名，不含版本号，供 workflow Dynamic Rename 步骤使用
ZIP_NAME="${APP_NAME}-${LABEL}.zip"

echo "🔨 编译 ${ARCH}（${LABEL}）..."
swift build -c release --arch "${ARCH}"

echo "📦 打包 .app..."
rm -rf dist && mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"

if [ -f "${LEGACY_BIN_PATH}" ]; then
    BIN_PATH="${LEGACY_BIN_PATH}"
elif [ -f "${XCBUILD_BIN_PATH}" ]; then
    BIN_PATH="${XCBUILD_BIN_PATH}"
else
    # 兜底：全目录搜索一次，防止未来工具链又换了布局
    BIN_PATH="$(find .build -type f -name "${APP_NAME}" \( -path "*/Release/*" -o -path "*/release/*" \) -not -path "*.dSYM/*" 2>/dev/null | head -1)"
fi

if [ -z "${BIN_PATH}" ] || [ ! -f "${BIN_PATH}" ]; then
    echo "❌ 找不到可执行文件，已尝试："
    echo "   - ${LEGACY_BIN_PATH}"
    echo "   - ${XCBUILD_BIN_PATH}"
    exit 1
fi
echo "✅ 找到可执行文件：${BIN_PATH}"

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
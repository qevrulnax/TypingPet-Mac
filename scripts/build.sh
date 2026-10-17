#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! xcrun --find swift >/dev/null 2>&1; then
  echo '请先安装 Apple Command Line Tools（终端运行 xcode-select --install），安装后重试。'
  exit 1
fi
ARCH="${ARCH:-arm64}"
if [[ "$ARCH" != arm64 && "$ARCH" != x86_64 ]]; then echo 'ARCH 必须为 arm64 或 x86_64'; exit 1; fi
swift test
swift build -c release --arch "$ARCH"
BIN_DIR="$(swift build -c release --arch "$ARCH" --show-bin-path)"
APP="dist/TypingPet.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/TypingPet" "$APP/Contents/MacOS/TypingPet"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --deep --sign - --identifier com.typingpet.mac "$APP"
codesign --verify --deep --strict "$APP"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP" "dist/TypingPet-$ARCH.zip"
mkdir -p dist/dmg-stage
/usr/bin/ditto "$APP" dist/dmg-stage/TypingPet.app
ln -sfn /Applications dist/dmg-stage/Applications
hdiutil create -volname TypingPet -srcfolder dist/dmg-stage -ov -format UDZO "dist/TypingPet-$ARCH.dmg"
echo "构建完成：$PWD/dist"

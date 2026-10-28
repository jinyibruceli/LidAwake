#!/bin/zsh
# Build a universal LidAwake.app into build/ and a zip into dist/.
set -e
cd "$(dirname "$0")"
APP=build/LidAwake.app
rm -rf build dist && mkdir -p "$APP/Contents/MacOS" dist
for arch in arm64 x86_64; do
  swiftc -O -target $arch-apple-macos13.0 main.swift -o build/LidAwake-$arch
done
lipo -create build/LidAwake-arm64 build/LidAwake-x86_64 -output "$APP/Contents/MacOS/LidAwake"
rm build/LidAwake-*
cp Info.plist "$APP/Contents/Info.plist"
codesign --force -s - "$APP"
ditto -c -k --keepParent "$APP" dist/LidAwake.zip
echo "built $APP and dist/LidAwake.zip"

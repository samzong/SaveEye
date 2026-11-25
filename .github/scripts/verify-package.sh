set -euo pipefail

version="$1"
core="$2"
build="$3"
hdiutil verify "build/Release/SaveEye-${version}-arm64.dmg"
plist=build/Release/SaveEye.app/Contents/Info.plist
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist")" = "$core"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$plist")" = "$build"
test "$(lipo -archs build/Release/SaveEye.app/Contents/MacOS/SaveEye)" = arm64

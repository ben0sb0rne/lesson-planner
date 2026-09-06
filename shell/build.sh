#!/bin/bash
# Build Lesson Planner.app — a native window around the hosted app.
#
# Needs nothing but the Xcode command line tools, which macOS already has if
# you've ever run `git`. No Node, no npm, no dependencies to keep current.
#
#   ./build.sh            build into ./dist
#   ./build.sh --install  build, then move it to /Applications
set -euo pipefail
cd "$(dirname "$0")"

APP="Lesson Planner"
BUNDLE="dist/$APP.app"
ID="com.benosborne.lessonplanner"

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

echo "→ compiling"
swiftc -O LessonPlanner.swift -o "$BUNDLE/Contents/MacOS/$APP" \
       -framework Cocoa -framework WebKit -target arm64-apple-macos11.0

echo "→ icon"
# Reuse the app's own PNG rather than keeping a second source of truth.
ICONSET=$(mktemp -d)/icon.iconset
mkdir -p "$ICONSET"
for s in 16 32 64 128 256 512; do
  sips -z $s $s ../icon-512.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null 2>&1
  sips -z $((s*2)) $((s*2)) ../icon-512.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null 2>&1
done
iconutil -c icns "$ICONSET" -o "$BUNDLE/Contents/Resources/icon.icns"

echo "→ bundle"
cat > "$BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>$APP</string>
  <key>CFBundleDisplayName</key><string>$APP</string>
  <key>CFBundleExecutable</key><string>$APP</string>
  <key>CFBundleIdentifier</key><string>$ID</string>
  <key>CFBundleIconFile</key><string>icon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSHumanReadableCopyright</key><string>Ben Osborne</string>
</dict></plist>
PLIST
plutil -lint "$BUNDLE/Contents/Info.plist" >/dev/null

# Ad-hoc signature. Enough for a local build; there is nothing to notarise
# because nothing is being distributed.
codesign --force --deep --sign - "$BUNDLE" 2>/dev/null || echo "  (unsigned — fine locally)"

if [ "${1:-}" = "--install" ]; then
  rm -rf "/Applications/$APP.app"
  cp -R "$BUNDLE" /Applications/
  echo "✓ installed to /Applications/$APP.app"
else
  echo "✓ built $BUNDLE"
fi

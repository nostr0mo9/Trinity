#!/bin/bash
set -e

echo "Building Trinity Project..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

BUILD_DIR="build"
APP_NAME="Trinity.app"
APP_BUNDLE="$BUILD_DIR/$APP_NAME"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
DAEMONS="$CONTENTS/Library/LaunchDaemons"

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS"
mkdir -p "$DAEMONS"

echo "Compiling TrinityDaemon..."
swiftc Daemon/main.swift Daemon/HostsManager.swift Shared/TrinityConfig.swift -o "$MACOS/TrinityDaemon"

echo "Compiling Main App..."
swiftc UI_App/TrinityApp.swift UI_App/ContentView.swift Shared/TrinityConfig.swift -parse-as-library -o "$MACOS/Trinity"

echo "Compiling trinity CLI..."
swiftc trinity/main.swift Shared/TrinityConfig.swift -o "$BUILD_DIR/trinity"

echo "Creating App Bundle Info.plist..."
cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Trinity</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourname.Trinity</string>
    <key>CFBundleName</key>
    <string>Trinity</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>SMPrivilegedExecutables</key>
    <dict>
        <key>com.trinity.daemon</key>
        <string>identifier com.trinity.daemon</string>
    </dict>
</dict>
</plist>
EOF

echo "Copying LaunchDaemon plist..."
cp com.trinity.daemon.plist "$DAEMONS/com.trinity.daemon.plist"

echo "Signing App Bundle..."
codesign -s - --force --deep "$APP_BUNDLE"

echo "----------------------------------------"
echo "Build complete! Artifacts are in $BUILD_DIR/"
echo "----------------------------------------"
echo ""
echo "To install the CLI, run:"
echo "sudo cp build/trinity /usr/local/bin/trinity"
echo ""
echo "To run the App, double click: build/Trinity.app"
echo "Then click 'Start Blocker' to install the Daemon."

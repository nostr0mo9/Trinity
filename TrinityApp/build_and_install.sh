#!/bin/bash
set -e

echo "Building Trinity System Ecosystem..."
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

BUILD_DIR="build/Trinity.app"
EXT_DIR="$BUILD_DIR/Contents/Library/SystemExtensions/com.nostr0mo9.trinity.extension.systemextension"
MAC_DIR="$BUILD_DIR/Contents/MacOS"

rm -rf build/
mkdir -p "$EXT_DIR/Contents/MacOS"
mkdir -p "$MAC_DIR"

echo "Generating Network Extension Property Lists..."
cat <<EOF > "$EXT_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.nostr0mo9.trinity.extension</string>
    <key>CFBundleName</key>
    <string>TrinityExtension</string>
    <key>CFBundlePackageType</key>
    <string>XPC!</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.networkextension.filter-data</string>
        <key>NSExtensionPrincipalClass</key>
        <string>FilterDataProvider</string>
    </dict>
    <key>NSSystemExtensionUsageDescription</key>
    <string>Trinity strictly requires traffic capabilities to enforce your configured distraction filter.</string>
</dict>
</plist>
EOF

cat <<EOF > build/ext.entitlements
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.nostr0mo9.trinity</string>
    </array>
    <key>com.apple.developer.networking.networkextension</key>
    <array>
        <string>content-filter-provider</string>
    </array>
</dict>
</plist>
EOF

cat <<EOF > build/cli.entitlements
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.nostr0mo9.trinity</string>
    </array>
    <key>com.apple.system-extension.install</key>
    <true/>
</dict>
</plist>
EOF

cat <<EOF > "$BUILD_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.nostr0mo9.trinity</string>
    <key>CFBundleName</key>
    <string>Trinity</string>
</dict>
</plist>
EOF

echo "Compiling Native Extension Code..."
swiftc Extension/main.swift Extension/FilterDataProvider.swift Shared/TrinityConfig.swift -o "$EXT_DIR/Contents/MacOS/com.nostr0mo9.trinity.extension"

echo "Compiling Trinity Core CLI..."
swiftc trinity/main.swift Shared/TrinityConfig.swift -o "$MAC_DIR/trinity"

echo "Codesigning Architectures (REQUIRES VALID PROVISIONING PROFILES IN SYSTEM FOR PRODUCTION)..."
codesign --force --sign - --entitlements build/ext.entitlements --timestamp=none "$EXT_DIR/Contents/MacOS/com.nostr0mo9.trinity.extension" || echo "Ignoring local ad-hoc sign errors."
codesign --force --sign - "$EXT_DIR" || echo "Ignoring generic sign errors."

codesign --force --sign - --entitlements build/cli.entitlements --timestamp=none "$MAC_DIR/trinity" || echo "Ignoring local ad-hoc sign errors."
codesign --force --sign - "$BUILD_DIR" || echo "Ignoring generic sign errors."

echo "----------------------------------------"
echo "Build complete! Container is wrapped in build/Trinity.app"
echo "----------------------------------------"
echo ""
echo "To orchestrate the system globally:"
echo "sudo cp -R build/Trinity.app /Applications/Trinity.app"
echo "sudo ln -sf /Applications/Trinity.app/Contents/MacOS/trinity /usr/local/bin/trinity"
echo ""
echo "Then, trigger native deployment:"
echo "sudo trinity start"


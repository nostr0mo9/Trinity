#!/bin/bash
set -e

echo "Building Trinity CLI Ecosystem..."

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

BUILD_DIR="build"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Compiling TrinityDaemon..."
swiftc Daemon/main.swift Daemon/HostsManager.swift Shared/TrinityConfig.swift -o "$BUILD_DIR/TrinityDaemon"

echo "Compiling trinity CLI..."
swiftc trinity/main.swift Shared/TrinityConfig.swift -o "$BUILD_DIR/trinity"

echo "----------------------------------------"
echo "Build complete! Artifacts are in $BUILD_DIR/"
echo "----------------------------------------"

cp ../README.md "$BUILD_DIR/README.md" 2>/dev/null || echo "No global README found to package."
cd "$BUILD_DIR"
zip -q trinity-release.zip trinity TrinityDaemon README.md 2>/dev/null || zip -q trinity-release.zip trinity TrinityDaemon
cd ..

echo ""
echo "To install the ecosystem globally, run:"
echo "sudo mkdir -p '/Library/Application Support/Trinity'"
echo "sudo cp build/TrinityDaemon '/Library/Application Support/Trinity/TrinityDaemon'"
echo "sudo cp com.trinity.daemon.plist /Library/LaunchDaemons/com.trinity.daemon.plist"
echo "sudo chmod 644 /Library/LaunchDaemons/com.trinity.daemon.plist"
echo "sudo cp build/trinity /usr/local/bin/trinity"
echo ""
echo "Then, start the blocker natively:"
echo "sudo trinity start"

# Trinity

Trinity is a ruthless, terminal-based, system-wide website blocker for macOS. 

Unlike browser extensions that can be casually disabled, Trinity manipulates your routing tables at the root level using an invisible background UNIX daemon. It implements a **ratchet mechanism**: adding websites to the blocklist is instant and unconditionally allowed, but removing a website requires surviving a gauntlet of 100 continuously generated math problems to "unlock" the system for a 30-minute grace period.

There is no GUI. There is no easy "off" switch. 

## Features
- **Root-Level Enforcement:** Modifies `/etc/hosts` to completely blackout domains (including IPv6 loops) across all browsers system-wide.
- **Fail-Closed Architecture:** Killing the daemon does not unblock your internet. The background process is the only piece of the software authorized to safely tear down the blocks when unlocked.
- **Math Challenge Unlock:** 100 generated arithmetic challenges required to grant yourself a 30-minute grace period to edit the blocklist.
- **Headless Ecosystem:** Managed entirely through the `trinity` CLI tool.
- **Auto-Updater:** Uses an embedded `sudo trinity update` pipeline that fetches pre-compiled binaries directly from GitHub releases with rollback-safe atomic transactions.

---

## Installation

### Method 1: Install from Source (Recommended for Developers)
1. Clone this repository:
   ```bash
   git clone https://github.com/nostr0mo9/Trinity.git
   cd Trinity/TrinityApp
   ```
2. Compile and package the resources using the build script:
   ```bash
   ./build_and_install.sh
   ```
3. Follow the output instructions to copy the compiled binaries and `com.trinity.daemon.plist` to their system directories:
   ```bash
   sudo mkdir -p '/Library/Application Support/Trinity'
   sudo cp build/TrinityDaemon '/Library/Application Support/Trinity/TrinityDaemon'
   sudo cp com.trinity.daemon.plist /Library/LaunchDaemons/com.trinity.daemon.plist
   sudo chmod 644 /Library/LaunchDaemons/com.trinity.daemon.plist
   sudo cp build/trinity /usr/local/bin/trinity
   ```

### Method 2: Auto-Update 
If you already have a version installed globally, simply run:
```bash
sudo trinity update
```
The CLI will dynamically pull the `trinity-release.zip` package from the latest GitHub Release and gracefully transition the system binaries for you.

---

## Usage

Once you have installed Trinity, it won't actually do anything until you explicitly turn the background service on. macOS uses a native tool called `launchctl` to manage background daemon tasks. Trinity wraps this complex tool perfectly for you under the hood—which basically just means you need to run `sudo trinity start` to connect everything!

### Starting the Daemon
```bash
sudo trinity start
```
*This boots the background daemon securely to `root`. It will automatically begin enforcing blocks instantly.*

### Command Reference

*   `trinity help` — Prints the quick-reference guide for all commands.
*   `trinity version` — Displays the currently installed version of Trinity.
*   `trinity block <domain>` — Instantly adds a domain (e.g., `x.com`) to the system blocklist.
*   `trinity unblock <domain>` — Safely strips a domain out. *(Fails instantly if the system is locked)*.
*   `trinity list` — Prints out everything currently blocked.
*   `trinity status` — Neatly outputs whether the daemon is actively running and whether your system is LOCKED or UNLOCKED.
*   `trinity unlock` — Triggers the 100-question math challenge to authorize changes.

**Management (Requires Sudo):**
*   `sudo trinity start` — Boots the background daemon. Enforces the blocklist globally.
*   `sudo trinity stop` — Shuts down the background service. *(Fails instantly if the system is locked, preventing you from casually killing the blocker)*.
*   `sudo trinity update` — Automatically patches your locally installed binaries with the latest GitHub release.

---

## Security Model & Data Paths
- **Executable Paths**: `trinity` lives universally at `/usr/local/bin/trinity`. The actual enforcer is isolated at `/Library/Application Support/Trinity/TrinityDaemon`.
- **Persistent Data**: The blocklists and locking state logic are stored safely inside `/Users/Shared/Trinity/`. Because the daemon cleanly separates executables from user data, updating the CLI code will never reset your lists or allow you to escape an active math challenge restriction.

> **Note:** Because Trinity runs as a system LaunchDaemon, it automatically survives computer restarts. Once you install and start the daemon, the blocker will automatically boot up silently in the background every single time you turn on your Mac, even before you log in!

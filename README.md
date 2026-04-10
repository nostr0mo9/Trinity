# ⬛️ Trinity ⬛️

Trinity is a ruthless, terminal-based, system-wide website blocker engineered natively for both **macOS** and **Windows**. 

Unlike browser extensions that can be casually disabled, Trinity manipulates your routing tables at the root OS level using invisible background engines (macOS LaunchDaemons and native Windows Services). It implements a **ratchet mechanism**: adding websites to the blocklist is instant and unconditionally allowed, but removing a website requires surviving a gauntlet of 100 continuously generated math problems to "unlock" the system for a 30-minute grace period.

There is no GUI. There is no easy "off" switch. 

## Features
- **Root-Level Enforcement:** Modifies primary system routing tables (including IPv6 loops) to completely blackout domains system-wide across all browsers.
- **Fail-Closed Architecture:** Killing the daemon does not seamlessly unblock your internet. The background process is the only piece of the software mathematically authorized to perfectly reconstruct and tear down the tables.
- **Math Challenge Unlock:** 100 dynamic arithmetic challenges required to grant yourself a 30-minute grace period to edit the blocklist.
- **Headless Ecosystem:** Managed entirely through the `trinity` CLI tool with a striking terminal ASCII interface.

---

## Installation & Architecture

The repository operates as a "Monorepo" containing two entirely separate, highly optimized native codebases:

### 🍏 macOS (`TrinityMac/`)
* **Environment:** Pure Swift and native Apple extensions.
* **Engine:** Headless `launchctl` Daemon manipulating `/etc/hosts` and `dscacheutil`.

**Installation (From Source):**
```bash
git clone https://github.com/nostr0mo9/Trinity.git
cd Trinity/TrinityMac
./build_and_install.sh
```
Follow the terminal output to drop the compiled binaries into their system directories.

**Auto-Update:** Mac users can dynamically bypass building from source by letting the CLI pull the latest pre-compiled releases from GitHub:
```bash
sudo trinity update
```

### 🪟 Windows (`TrinityWindows/`)
* **Environment:** Pure Golang (statically linked for maximum portability).
* **Engine:** Headless Go ecosystem bound perpetually as a native background `Windows Service`.

**Installation (From Source):**
*(Requires Go 1.21+ installed)*
```powershell
git clone https://github.com/nostr0mo9/Trinity.git
cd Trinity\TrinityWindows
go build -o trinity-daemon.exe cmd\daemon\main.go
go build -o trinity.exe cmd\trinity\main.go
```

---

## 🧮 Usage (Cross-Platform)

Once installed, standard management is identical across platforms:

*   `trinity help` — Prints the quick-reference manual.
*   `trinity version` — Displays the matrix version installed locally.
*   `trinity block <domain>` — Instantly adds a domain (e.g., `x.com`) to the system blocklist.
*   `trinity unblock <domain>` — Safely strips a domain out. *(Fails instantly if locked)*.
*   `trinity list` — Prints out everything currently blocked.
*   `trinity status` — Outputs daemon health and your LOCKED/UNLOCKED access parameters.
*   `trinity unlock` — Triggers the 100-question math challenge to authorize changes over a 30-minute grace period.

**Administrative Management (Requires Sudo/Run as Administrator):**
*   `trinity start` — Boots the background service to the system root. Enforces the blocklist globally.
*   `trinity stop` — Shuts down the background service. *(Fails instantly if locked)*.
*   `trinity delete` — Completely tears down the daemon, destroys the system configurations perfectly, and deletes itself. *(Fails instantly if locked)*.

---

## 🚨 Emergency Administrator Recovery

We designed Trinity to be mathematically ruthless, but it is **not** malware. If files are accidentally deleted or a catastrophic system failure occurs, it will "Fail-Closed" and rigidly maintain the blocks.

However, there is always a supported administrative escape hatch:

**Option 1: Re-Installation (Recommended)**
If you delete the `trinity` CLI to bypass the lock, the Math Challenge becomes wildly inaccessible. To get it back, you do not need to start over! Simply download the latest release or recompile from GitHub. Re-running the installation magically re-attaches to the indestructible background daemon, returning your access to the `trinity unlock` feature natively.

**Option 2: Nuclear Uninstall (Disaster Recovery)**
If you undergo catastrophic software failure and cannot securely invoke `trinity delete`, you must manually purge the system frameworks:

**macOS:**
```bash
# 1. Kill the background daemon
sudo launchctl bootout system/com.trinity.daemon

# 2. Restore your pristine networking routing configurations
sudo cp '/Library/Application Support/Trinity/hosts.backup' /etc/hosts

# 3. Clean out the application environments
sudo rm -rf '/Library/Application Support/Trinity' '/Users/Shared/Trinity' /usr/local/bin/trinity
```

**Windows:**
1. Stop the `TrinityDaemon` natively inside `services.msc`.
2. Open `C:\Windows\System32\drivers\etc\hosts` as an Administrator and erase the `# --- TRINITY START ---` payload natively.
3. Delete all lingering `.exe` dependencies on your hard drive manually.

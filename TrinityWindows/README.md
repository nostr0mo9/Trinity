# Trinity: Windows Native MVP

Trinity is a hardcore, terminal-first website blocker translated natively from macOS Swift into a robust Golang architecture custom-built for Windows 10/11 environments.

It pairs deeply with a custom "Cyber Matrix" ANSI-rendered CLI interface and strict mathematical challenges meant to actively obstruct you from unlocking your distraction filters.

## Windows Architecture Limitations vs macOS

Unlike the hardcore macOS "Fail-Closed" version which uses low-level system extensions and RAM loops to aggressively fight administrative tampering, this Windows variant represents an **MVP Level**.

It is implemented as a standard system service targeting the native hosts routing.
- **Enforcement Layer:** Modifies `C:\Windows\System32\drivers\etc\hosts` to securely drop blacklisted domains to `0.0.0.0` or `::1`, and flushes active browser DNS tracking.
- **Inter-Process Communication:** Relies on strict Named Pipes via `\\.\pipe\TrinityControlPipe` to handle instruction routing securely between the unprivileged terminal CLI and the elevated background `trinity-daemon.exe`.

> **Note:** Because this version relies heavily on standard native service structures, any user with deep Registry GUI knowledge and Administrator privileges *can* manually modify their own hosts file via raw Notepad bypasses.

## Resurrective State Recovery

Because standard config files are vulnerable to casual file-deletion bypass tricks, Trinity incorporates a resilient native recovery loop:
If you wipe the physical `C:\ProgramData\Trinity\config.json` folder in an attempt to subvert the locked state, Trinity simply intercepts the boot sequence, reverse-parses the system `hosts` file dynamically, and flawlessly reconstructs the lock rules back into pure active memory!

## Installation & Setup

You must natively compile the system directly in Go.
1. Make sure you have Golang installed successfully on Windows.
2. Initialize dependencies:
   ```powershell
   go mod tidy
   ```
3. Compile both halves of the split-architecture:
   ```powershell
   go build -o trinity.exe ./cmd/trinity
   go build -o trinity-daemon.exe ./cmd/daemon
   ```
4. *(Optional but Recommended)* Add the directory to your system `PATH` so you can call `trinity` from any PowerShell window globally!

## Interface & Usage

### Administrative Engine Control
You **must** run these commands inside an **Administrator PowerShell** instance. They register and unregister the background service to the native runtime.
- `trinity start` — Embeds and launches the background daemon softly mapping to SCM.
- `trinity stop` — Halts the daemon and cleanly unsubscribes the Windows Service safely.
- `trinity delete` — Triggers the physical un-installer sequences, cleans the artifacts, and securely auto-deletes the two primary compiled binaries.

### Unprivileged Standard Control
You can execute these actions freely from any normal PowerShell Terminal:
- `trinity block <domain>` — Enforce restrictions on a specific website.
- `trinity unblock <domain>` — Remove restrictions (Only available if the environment is `UNLOCKED`).
- `trinity list` — Renders the Cyber Matrix UI tracking what is currently restricted.
- `trinity status` — Quick view determining whether the daemon is actively linked.
- `trinity unlock` — Triggers the 100-problem mathematical challenge sequence.

## The Mathematical Lock

When you trigger `trinity unlock`, you will be immediately presented with an interactive test.
- You must solve 100 consecutive arithmetic problems correctly.
- Incorrect answers forcefully reject the input.
- You can abort the sequence gracefully at any time by pressing `Ctrl+C` or exclusively typing `quit`.

If you solve all 100 problems, you are granted a temporary **30-minute grace period** where the daemon artificially disconnects the hosts restrictions internally without dropping the registered targets! After 30 minutes, it automatically locks down again.

import Foundation
import CryptoKit

let applyUnlockFlag = "--apply-unlock"
let TRINITY_VERSION = "v1.0.0"

let themeColor = "\u{001B}[36m" // Cyan by default
let red = "\u{001B}[31m"
let green = "\u{001B}[32m"
let dim = "\u{001B}[90m"
let reset = "\u{001B}[0m"
let bold = "\u{001B}[1m"

// Variables imported from Shared folder

func loadConfig() -> TrinityConfig {
    if let data = try? Data(contentsOf: TrinityPaths.configURL),
       let config = try? JSONDecoder().decode(TrinityConfig.self, from: data) {
        return config
    }
    return TrinityConfig(blockedDomains: [])
}

func saveConfig(_ config: TrinityConfig) {
    do {
        try FileManager.default.createDirectory(at: TrinityPaths.appSupportDir, withIntermediateDirectories: true, attributes: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(config)
        try data.write(to: TrinityPaths.configURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: TrinityPaths.configURL.path)
    } catch {}
}

func getLockInfo() -> (isLocked: Bool, unlockDate: Date?) {
    if let data = try? Data(contentsOf: TrinityPaths.stateURL),
       let state = try? JSONDecoder().decode(TrinityState.self, from: data) {
        if state.isCurrentlyUnlocked {
            return (false, state.unlockedUntil)
        }
    }
    return (true, nil)
}

func getDaemonRunning() -> Bool {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    process.arguments = ["print", "system/com.trinity.daemon"]
    process.standardOutput = Pipe(); process.standardError = Pipe()
    try? process.run(); process.waitUntilExit()
    return process.terminationStatus == 0
}

// --- CORE UI MATRIX CONTROLLER ---
func printCyberPanel(headerTitle: String? = nil, domains: [String]? = nil, customLines: [(text: String, color: String)]? = nil) {
    let info = getLockInfo()
    let isLocked = info.isLocked
    let isDaemonActive = getDaemonRunning()
    
    let titleStr = headerTitle ?? (isDaemonActive ? "DAEMON: ACTIVE" : "DAEMON: OFFLINE")
    let title = "T R I N I T Y : : \(titleStr)"
    let statusText = isLocked ? "STATUS: ENFORCED :: DISTRACTION FILTER ACTIVE" : "STATUS: STANDBY :: FILTER OFFLINE"
    
    func centerPad(_ t: String, w: Int) -> String {
        let pad = max(0, w - t.count)
        return String(repeating: " ", count: pad/2) + t + String(repeating: " ", count: pad - pad/2)
    }
    func rightPad(_ t: String, w: Int) -> String {
        let pad = max(0, w - t.count)
        return t + String(repeating: " ", count: pad)
    }
    
    print("")
    print("\(themeColor)0101010101010101010101010101010101010101010101010101010101010101\(reset)")
    print("\(themeColor)0\(reset)\(bold)\(centerPad(title, w: 62))\(reset)\(themeColor)0\(reset)")
    print("\(themeColor)01\(reset) \(centerPad(statusText, w: 60))\(themeColor)10\(reset)")
    print("\(themeColor)010\(reset)\(themeColor)\(String(repeating: "-", count: 58))\(reset)\(themeColor)010\(reset)")
    
    let fullBinLeft = "0101010101010101"
    let fullBinRight = "1010101010101010"
    
    if let lines = customLines {
        for (index, line) in lines.enumerated() {
            let leftLen = 4 + (index % 5)
            let rightLen = 4 + (index % 5)
            
            let lBin = String(fullBinLeft.prefix(leftLen))
            let rBin = String(fullBinRight.prefix(rightLen))
            let lPad = String(repeating: " ", count: 9 - leftLen)
            
            let inner = 47
            let cleanLen = line.text.count
            let padCount = max(0, inner - cleanLen)
            let totalPad = String(repeating: " ", count: padCount)
            
            print("\(themeColor)\(lBin)\(reset)\(lPad)\(line.color)\(line.text)\(reset)\(totalPad)\(themeColor)\(rBin)\(reset)")
        }
    } else {
        let displayDomains = domains ?? loadConfig().blockedDomains
        if displayDomains.isEmpty {
            print("\(themeColor)0101\(reset)   \(centerPad("NO DOMAINS BLOCKED", w: 54))   \(themeColor)1010\(reset)")
        } else {
            for (index, domain) in displayDomains.enumerated() {
                let leftLen = 4 + (index % 5)
                let rightLen = 4 + (index % 5)
                
                let lBin = String(fullBinLeft.prefix(leftLen))
                let rBin = String(fullBinRight.prefix(rightLen))
                let lPad = String(repeating: " ", count: 9 - leftLen)
                let rPad = String(repeating: " ", count: 9 - rightLen)
                
                let cleanDomain = "[X] \(domain)"
                let stateSuffix = isLocked ? "BLOCKED" : "UNLOCKED"
                let stateColor = isLocked ? red : green
                
                let inner = 46
                let colonsCount = max(1, inner - cleanDomain.count - stateSuffix.count - 1)
                let colons = String(repeating: ":", count: colonsCount)
                
                print("\(themeColor)\(lBin)\(reset)\(lPad)\(cleanDomain) \(dim)\(colons)\(reset) \(stateColor)\(stateSuffix)\(reset)\(rPad)\(themeColor)\(rBin)\(reset)")
            }
        }
    }
    
    print("\(themeColor)0101\(reset)\(themeColor)\(String(repeating: "-", count: 56))\(reset)\(themeColor)1010\(reset)")
    
    let accessText = isLocked ? "ACCESS: DENIED :: OVERRIDE: DISABLED" : "ACCESS: GRANTED :: OVERRIDE: ENABLED"
    var userStateText = "USER STATE: LOCKED :: SOLVE REQUIRED"
    if !isLocked {
        if let expire = info.unlockDate {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            userStateText = "USER STATE: UNLOCKED :: EXPIRES \(formatter.string(from: expire))"
        } else {
            userStateText = "USER STATE: UNLOCKED"
        }
    }
    let footerTitle = "T R I N I T Y   I S   W A T C H I N G"
    
    print("\(themeColor)010\(reset)   \(isLocked ? red : green)\(rightPad(accessText, w: 56))\(reset)\(themeColor)010\(reset)")
    print("\(themeColor)01\(reset)    \(isLocked ? red : green)\(rightPad(userStateText, w: 57))\(reset)\(themeColor)10\(reset)")
    print("\(themeColor)0\(reset)\(bold)\(dim)\(centerPad(footerTitle, w: 62))\(reset)\(themeColor)0\(reset)")
    print("\(themeColor)0101010101010101010101010101010101010101010101010101010101010101\(reset)")
    print("")
}

// --- COMMAND IMPLEMENTATIONS ---

func runBlock(domain: String) {
    let clean = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if clean.isEmpty { return }
    var config = loadConfig()
    if !config.blockedDomains.contains(clean) {
        config.blockedDomains.append(clean)
        saveConfig(config)
        printCyberPanel(headerTitle: "TARGET ACQUIRED", customLines: [("Successfully restricted routing for:", reset), ("  -> \(clean)", green)])
    } else {
        printCyberPanel(headerTitle: "TARGET ACQUIRED", customLines: [("\(clean) is already restricted.", dim)])
    }
}

func runUnblock(domain: String) {
    if getLockInfo().isLocked {
        printCyberPanel(headerTitle: "ACCESS DENIED", customLines: [("System is LOCKED.", red), ("You cannot remove domains.", red), ("Run `trinity unlock` to gain access.", dim)])
        exit(1)
    }
    
    let clean = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    var config = loadConfig()
    if let idx = config.blockedDomains.firstIndex(of: clean) {
        config.blockedDomains.remove(at: idx)
        saveConfig(config)
        printCyberPanel(headerTitle: "TARGET RELEASED", customLines: [("Successfully lifted restriction for:", reset), ("  -> \(clean)", green)])
    } else {
        printCyberPanel(headerTitle: "TARGET NOT FOUND", customLines: [("\(clean) is not in the blocklist.", dim)])
    }
}

func runList() {
    printCyberPanel(headerTitle: "B L O C K L I S T")
}

func printStatus() {
    printCyberPanel()
}

func runStart() {
    if getuid() != 0 {
        printCyberPanel(headerTitle: "INSUFFICIENT PRIVILEGES", customLines: [("Error: `trinity start` must be run with sudo.", red)])
        exit(1)
    }
    let cleanup = Process()
    cleanup.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    cleanup.arguments = ["bootout", "system/com.trinity.daemon"]
    try? cleanup.run(); cleanup.waitUntilExit()
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    process.arguments = ["bootstrap", "system", "/Library/LaunchDaemons/com.trinity.daemon.plist"]
    do {
        try process.run(); process.waitUntilExit()
        if process.terminationStatus == 0 {
            printCyberPanel(headerTitle: "SYSTEM BOOT", customLines: [("Daemon boot sequence successful.", green), ("Trinity is now active in the background.", green)])
        } else {
            printCyberPanel(headerTitle: "SYSTEM BOOT FAILED", customLines: [("Failed to start daemon. Already running?", red)])
        }
    } catch {
        print("Execution error: \(error)")
    }
}

func runStop() {
    if getuid() != 0 {
        printCyberPanel(headerTitle: "INSUFFICIENT PRIVILEGES", customLines: [("Error: `trinity stop` must be run with sudo.", red)])
        exit(1)
    }
    if getLockInfo().isLocked {
        printCyberPanel(headerTitle: "ACCESS DENIED", customLines: [("Error: System is LOCKED.", red), ("You cannot stop the daemon right now.", red), ("Run `trinity unlock` to gain temporary access.", dim)])
        exit(1)
    }
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    process.arguments = ["bootout", "system/com.trinity.daemon"]
    do {
        try process.run(); process.waitUntilExit()
        if process.terminationStatus == 0 {
            printCyberPanel(headerTitle: "SYSTEM TEARDOWN", customLines: [("Trinity background daemon safely stopped.", green)])
        } else {
            printCyberPanel(headerTitle: "TEARDOWN FAILED", customLines: [("Failed to stop daemon. Is it running?", red)])
        }
    } catch {
        print("Execution error: \(error)")
    }
}

func printHelp() {
    let lines = [
        ("Usage Commands:", bold),
        ("  trinity block <domain>   - Restrict a remote website", reset),
        ("  trinity unblock <domain> - Remove restriction (if unlocked)", reset),
        ("  trinity list             - View current network policies", reset),
        ("  trinity status           - View daemon status & lock state", reset),
        ("  trinity unlock           - Subject yourself to the test", reset),
        ("  trinity version          - Display matrix version", reset),
        ("  trinity version          - Display matrix version", reset),
        ("  trinity delete           - Permanently uninstall Trinity", reset),
        ("", reset),
        ("Administrative (Requires Sudo):", bold),
        ("  sudo trinity start       - Boot the background layer", dim),
        ("  sudo trinity stop        - Tear down the background layer", dim),
        ("  sudo trinity update      - Pull updates from the grid", dim)
    ]
    printCyberPanel(headerTitle: "M A N U A L", customLines: lines)
}

func runVersion() {
    printCyberPanel(headerTitle: "V E R S I O N", customLines: [("Trinity CLI Layer", green), ("Grid Version: \(TRINITY_VERSION)", dim)])
}

// --- MATH & UPDATE ---
func startChallenge() {
    signal(SIGINT) { _ in
        print("\n\n\(red)Challenge aborted by user.\(reset)\n\n")
        exit(0)
    }
    
    print("\u{001B}[2J\u{001B}[H", terminator: "")
    printCyberPanel(headerTitle: "INITIATE PROTOCOL", customLines: [
        ("SUBJECT REQUESTED OVERRIDE.", red),
        ("You must complete 100 math sequences.", dim),
        ("Incorrect answers require a retry.", dim),
        ("Ctrl+C or type 'quit' to abort.", dim)
    ])
    
    let totalProblems = 100
    var completed = 0
    var usedProblems = Set<String>()
    
    // Simplistic problem generation
    while completed < totalProblems {
        var a = Int.random(in: 10...99)
        var b = Int.random(in: 10...99)
        let type = Int.random(in: 0...2)
        var q = ""
        var ans = 0
        if type == 0 { q = "\(a) + \(b)"; ans = a + b }
        else if type == 1 { q = "\(a+b) - \(a)"; ans = b }
        else { a = Int.random(in: 2...12); b = Int.random(in: 4...12); q = "\(a) × \(b)"; ans = a * b }
        
        if usedProblems.contains(q) { continue }
        usedProblems.insert(q)
        
        var solved = false
        while !solved {
            let progress = String(format: "%03d", completed + 1)
            print("\(themeColor)[\(progress)/\(totalProblems)]\(reset) \(bold)\(q) = \(reset)", terminator: "")
            guard let input = readLine() else { 
                print("\n\n\(red)Challenge aborted by user.\(reset)\n\n")
                exit(0) 
            }
            let cleanedInput = input.trimmingCharacters(in: .whitespaces).lowercased()
            if cleanedInput == "quit" {
                print("\n\n\(red)Challenge aborted by user.\(reset)\n\n")
                exit(0)
            }
            if cleanedInput.isEmpty { continue }
            if let pi = Int(cleanedInput) {
                if pi == ans {
                    solved = true; completed += 1;
                    if completed < totalProblems { print("\(green)  ↳ Correct\(reset)") }
                } else { print("\(red)  ↳ Incorrect. System rejects input.\(reset)") }
            } else { print("\(red)  ↳ Invalid input.\(reset)") }
        }
    }
    
    printCyberPanel(headerTitle: "PROTOCOL COMPLETE", customLines: [
        ("Challenge Sequence 100/100 verified.", green),
        ("Applying override mechanism...", dim)
    ])
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
    process.arguments = [CommandLine.arguments[0], applyUnlockFlag]
    try? process.run(); process.waitUntilExit()
}

func runApplyUnlock() {
    if getuid() != 0 { exit(1) }
    var currentHash: String? = nil
    if let data = try? Data(contentsOf: TrinityPaths.configURL) {
        currentHash = SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }
    var currentEnforced: [String]? = nil
    if let data = try? Data(contentsOf: TrinityPaths.stateURL), let st = try? JSONDecoder().decode(TrinityState.self, from: data) {
        currentEnforced = st.enforcedDomains
    }
    
    let state = TrinityState(unlockedUntil: Date().addingTimeInterval(30 * 60), configHash: currentHash, enforcedDomains: currentEnforced)
    if let data = try? JSONEncoder().encode(state) {
        try? data.write(to: TrinityPaths.stateURL, options: .atomic)
    }
    
    print("\u{001B}[2J\u{001B}[H", terminator: "")
    printCyberPanel(headerTitle: "OVERRIDE ACCEPTED", customLines: [
        ("The routing restrictions are temporarily severed.", green),
        ("Thirty-minute grace period active. Use it wisely.", dim)
    ])
}

func runUpdate() {
    if getuid() != 0 {
        printCyberPanel(headerTitle: "INSUFFICIENT PRIVILEGES", customLines: [("Error: `trinity update` must be run with sudo.", red)])
        exit(1)
    }

    print("\(themeColor)0101010101010  \(bold)Initiating grid communication... \(reset)")
    
    guard let url = URL(string: "https://api.github.com/repos/nostr0mo9/Trinity/releases/latest") else { exit(1) }
    var request = URLRequest(url: url)
    request.setValue("Trinity-Updater", forHTTPHeaderField: "User-Agent")
    
    let semaphore = DispatchSemaphore(value: 0)
    var responseData: Data?
    var httpError: Error?
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        responseData = data
        httpError = error
        semaphore.signal()
    }
    task.resume()
    semaphore.wait()
    
    guard let data = responseData, httpError == nil else {
        printCyberPanel(headerTitle: "OFFLINE", customLines: [("Failed to connect to GitHub. No signal detected.", red)])
        exit(1)
    }
    
    struct GitHubAsset: Decodable {
        let name: String
        let browser_download_url: String
    }
    struct GitHubRelease: Decodable {
        let tag_name: String
        let assets: [GitHubAsset]
    }
    
    guard let release = try? JSONDecoder().decode(GitHubRelease.self, from: data) else {
        printCyberPanel(headerTitle: "DECODE ERROR", customLines: [("Failed to parse remote datasets.", red)])
        exit(1)
    }
    
    printCyberPanel(headerTitle: "R E M O T E   V E R S I O N   P U L L E D", customLines: [
        ("Current Frame: \(TRINITY_VERSION)", dim),
        ("Remote Master: \(release.tag_name)", green)
    ])
    
    if release.tag_name == TRINITY_VERSION {
        printCyberPanel(headerTitle: "O P T I M I Z E D", customLines: [("You are already fully synchronized.", green)])
        exit(0)
    }
    
    guard let asset = release.assets.first(where: { $0.name == "trinity-release.zip" }) else {
        printCyberPanel(headerTitle: "ASSET MISSING", customLines: [("Latest release (\(release.tag_name)) does not contain trinity-release.zip", red)])
        exit(1)
    }
    
    print("\(themeColor)010101010  \(bold)Proceed with grid synchronisation? [y/N]: \(reset)", terminator: "")
    guard let answer = readLine()?.lowercased(), answer == "y" || answer == "yes" else {
        print("\(dim)Update cancelled.\(reset)")
        exit(0)
    }
    
    print("Downloading update...")
    let fm = FileManager.default
    let tmpDir = "/tmp/TrinityUpdateEnv"
    let zipPath = "\(tmpDir)/trinity-release.zip"
    
    try? fm.removeItem(atPath: tmpDir)
    try? fm.createDirectory(atPath: tmpDir, withIntermediateDirectories: true, attributes: nil)
    
    let curl = Process()
    curl.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
    curl.arguments = ["-sL", asset.browser_download_url, "-o", zipPath]
    try? curl.run()
    curl.waitUntilExit()
    
    guard curl.terminationStatus == 0, fm.fileExists(atPath: zipPath) else {
        printCyberPanel(headerTitle: "ARTIFACT FAILED", customLines: [("Failed to download update payload.", red)])
        exit(1)
    }
    
    let unzip = Process()
    unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
    unzip.arguments = ["-q", "-o", zipPath, "-d", tmpDir]
    try? unzip.run()
    unzip.waitUntilExit()
    
    guard unzip.terminationStatus == 0 else {
        printCyberPanel(headerTitle: "EXTRACTION FAILED", customLines: [("Failed to extract artifact.", red)])
        exit(1)
    }
    
    let newCli = "\(tmpDir)/trinity"
    let newDaemon = "\(tmpDir)/TrinityDaemon"
    
    guard fm.fileExists(atPath: newCli), fm.fileExists(atPath: newDaemon) else {
        printCyberPanel(headerTitle: "VALIDATION FAILED", customLines: [("Zip missing required binaries. Update aborted.", red)])
        exit(1)
    }
    
    print("Creating safe backups...")
    let cliTarget = "/usr/local/bin/trinity"
    let daemonTarget = "/Library/Application Support/Trinity/TrinityDaemon"
    let cliBackup = "/tmp/trinity.backup"
    let daemonBackup = "/tmp/TrinityDaemon.backup"
    
    try? fm.removeItem(atPath: cliBackup); try? fm.removeItem(atPath: daemonBackup)
    try? fm.copyItem(atPath: cliTarget, toPath: cliBackup)
    try? fm.copyItem(atPath: daemonTarget, toPath: daemonBackup)
    
    print("Transposing system layers...")
    let bootout = Process()
    bootout.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    bootout.arguments = ["bootout", "system/com.trinity.daemon"]
    bootout.standardOutput = Pipe(); bootout.standardError = Pipe()
    try? bootout.run(); bootout.waitUntilExit()
    
    do {
        try fm.removeItem(atPath: cliTarget); try fm.removeItem(atPath: daemonTarget)
        try fm.copyItem(atPath: newCli, toPath: cliTarget)
        try fm.copyItem(atPath: newDaemon, toPath: daemonTarget)
        
        let chown = Process()
        chown.executableURL = URL(fileURLWithPath: "/usr/sbin/chown")
        chown.arguments = ["root:wheel", cliTarget, daemonTarget]
        try chown.run(); chown.waitUntilExit()
        
        let chmod = Process()
        chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmod.arguments = ["755", cliTarget, daemonTarget]
        try chmod.run(); chmod.waitUntilExit()
        
    } catch {
        printCyberPanel(headerTitle: "CRITICAL FAILURE", customLines: [("Failed transposing files... Initiating ROLLBACK.", red)])
        try? fm.removeItem(atPath: cliTarget); try? fm.removeItem(atPath: daemonTarget)
        try? fm.copyItem(atPath: cliBackup, toPath: cliTarget)
        try? fm.copyItem(atPath: daemonBackup, toPath: daemonTarget)
        _ = try? Process.run(URL(fileURLWithPath: "/bin/launchctl"), arguments: ["bootstrap", "system", "/Library/LaunchDaemons/com.trinity.daemon.plist"])
        exit(1)
    }
    
    let bootstrap = Process()
    bootstrap.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    bootstrap.arguments = ["bootstrap", "system", "/Library/LaunchDaemons/com.trinity.daemon.plist"]
    bootstrap.standardOutput = Pipe(); bootstrap.standardError = Pipe()
    try? bootstrap.run(); bootstrap.waitUntilExit()
    
    let verify = Process()
    verify.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    verify.arguments = ["print", "system/com.trinity.daemon"]
    verify.standardOutput = Pipe(); verify.standardError = Pipe()
    try? verify.run(); verify.waitUntilExit()
    
    if verify.terminationStatus == 0 {
        printCyberPanel(headerTitle: "SYNCHRONIZATION COMPLETED", customLines: [("Trinity seamlessly updated to \(release.tag_name)", green)])
        try? fm.removeItem(atPath: cliBackup); try? fm.removeItem(atPath: daemonBackup)
        try? fm.removeItem(atPath: tmpDir)
    } else {
        printCyberPanel(headerTitle: "DAEMON RESTART FAILED", customLines: [("Daemon crashed... Initiating ROLLBACK.", red)])
        let clean = Process()
        clean.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        clean.arguments = ["bootout", "system/com.trinity.daemon"]
        clean.standardOutput = Pipe(); clean.standardError = Pipe()
        try? clean.run(); clean.waitUntilExit()
        
        try? fm.removeItem(atPath: cliTarget); try? fm.removeItem(atPath: daemonTarget)
        try? fm.copyItem(atPath: cliBackup, toPath: cliTarget)
        try? fm.copyItem(atPath: daemonBackup, toPath: daemonTarget)
        _ = try? Process.run(URL(fileURLWithPath: "/bin/launchctl"), arguments: ["bootstrap", "system", "/Library/LaunchDaemons/com.trinity.daemon.plist"])
        exit(1)
    }
}

func runDelete() {
    if getuid() != 0 {
        printCyberPanel(headerTitle: "INSUFFICIENT PRIVILEGES", customLines: [("Error: `trinity delete` must be run with sudo.", red)])
        exit(1)
    }
    if getLockInfo().isLocked {
        printCyberPanel(headerTitle: "ACCESS DENIED", customLines: [("Error: System is LOCKED.", red), ("You must unlock before uninstalling.", red), ("Run `trinity unlock` context.", dim)])
        exit(1)
    }
    
    print("\n\(themeColor)010\(reset)  \(bold)This will permanently uninstall Trinity from this Mac. Continue? [y/N] \(reset)", terminator: "")
    guard let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased(), input == "y" || input == "yes" else {
        print("\(dim)Uninstall cancelled.\(reset)\n")
        exit(0)
    }
    
    print("\n\(themeColor)0101010101010\(reset)  \(bold)Initiating deep teardown sequence... \(reset)")
    
    let bootout = Process()
    bootout.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    bootout.arguments = ["bootout", "system/com.trinity.daemon"]
    bootout.standardOutput = Pipe(); bootout.standardError = Pipe()
    try? bootout.run(); bootout.waitUntilExit()
    print("\(green)  ↳ Daemon hook severed.\(reset)")
    
    let hostsPath = "/etc/hosts"
    let startMarker = "# --- TRINITY START ---"
    let endMarker = "# --- TRINITY END ---"
    if let currentContent = try? String(contentsOfFile: hostsPath, encoding: .utf8), currentContent.contains(startMarker) {
        let lines = currentContent.components(separatedBy: .newlines)
        var newLines: [String] = []
        var inside = false
        for line in lines {
            if line == startMarker { inside = true; continue }
            if line == endMarker { inside = false; continue }
            if !inside { newLines.append(line) }
        }
        while newLines.last?.trimmingCharacters(in: .whitespaces).isEmpty == true { newLines.removeLast() }
        let newContent = newLines.joined(separator: "\n")
        try? newContent.write(toFile: hostsPath, atomically: true, encoding: .utf8)
        print("\(green)  ↳ System routing registry scrubbed.\(reset)")
    }
    
    _ = try? Process.run(URL(fileURLWithPath: "/usr/bin/dscacheutil"), arguments: ["-flushcache"]).waitUntilExit()
    _ = try? Process.run(URL(fileURLWithPath: "/usr/bin/killall"), arguments: ["-HUP", "mDNSResponder"]).waitUntilExit()
    print("\(green)  ↳ DNS cache formally wiped.\(reset)")
    print("\(green)  ↳ Application and configuration clusters destroyed.\(reset)")
    
    printCyberPanel(headerTitle: "A R C H I T E C T U R E   S H R E D D E D", customLines: [("Trinity has been fully uninstalled.", green)])
    
    let fm = FileManager.default
    try? fm.removeItem(atPath: "/Library/LaunchDaemons/com.trinity.daemon.plist")
    try? fm.removeItem(atPath: "/Library/Application Support/Trinity")
    try? fm.removeItem(atPath: "/Users/Shared/Trinity")
    try? fm.removeItem(atPath: "/usr/local/bin/trinity")
    exit(0)
}

// ... Router
let args = CommandLine.arguments
if args.contains(applyUnlockFlag) { runApplyUnlock(); exit(0) }

if args.count > 1 {
    switch args[1] {
    case "block": if args.count > 2 { runBlock(domain: args[2]) } else { printHelp() }
    case "unblock": if args.count > 2 { runUnblock(domain: args[2]) } else { printHelp() }
    case "list": runList()
    case "start": runStart()
    case "stop": runStop()
    case "status": printStatus()
    case "unlock": getLockInfo().isLocked ? startChallenge() : printCyberPanel(headerTitle: "NO ACTION REQUIRED", customLines: [("System is already unlocked. No math required!", green)])
    case "version": runVersion()
    case "delete": runDelete()
    case "help": printHelp()
    case "update": runUpdate()
    default: printHelp()
    }
} else {
    printHelp()
}

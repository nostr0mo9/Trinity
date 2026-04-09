import Foundation
import CryptoKit

let applyUnlockFlag = "--apply-unlock"

func runApplyUnlock() {
    if getuid() != 0 {
        print("\u{001B}[31mError: --apply-unlock must be run as root.\u{001B}[0m")
        exit(1)
    }
    
    var currentHash: String? = nil
    if let data = try? Data(contentsOf: TrinityPaths.configURL) {
        let digest = SHA256.hash(data: data)
        currentHash = digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    var currentEnforced: [String]? = nil
    if let stateData = try? Data(contentsOf: TrinityPaths.stateURL),
       let parsedState = try? JSONDecoder().decode(TrinityState.self, from: stateData) {
        currentEnforced = parsedState.enforcedDomains
    }
    
    let until = Date().addingTimeInterval(30 * 60)
    let state = TrinityState(unlockedUntil: until, configHash: currentHash, enforcedDomains: currentEnforced)
    
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(state)
        
        try? FileManager.default.createDirectory(at: TrinityPaths.appSupportDir, withIntermediateDirectories: true, attributes: nil)
        
        try data.write(to: TrinityPaths.stateURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: TrinityPaths.stateURL.path)
        
        print("""
        \u{001B}[2J\u{001B}[H
        \u{001B}[1;32m      [ UNLOCK SUCCESSFUL ]      \u{001B}[0m
        \u{001B}[36mThe restricted websites are now unblocked.\u{001B}[0m
        \u{001B}[90mYour 30-minute grace period begins now. Use it wisely.\u{001B}[0m
        
        """)
    } catch {
        print("\u{001B}[31mFailed to save state: \(error)\u{001B}[0m")
        exit(1)
    }
}

struct MathProblem: Hashable {
    let questionText: String
    let answer: Int
}

func generateUniqueProblem(used: inout Set<String>, index: Int) -> MathProblem {
    while true {
        var type = 0
        var qText = ""
        var ans = 0
        
        if index < 20 {
            type = Int.random(in: 0...1)
            switch type {
            case 0:
                let a = Int.random(in: 5...25)
                let b = Int.random(in: 5...25)
                qText = "\(a) + \(b)"
                ans = a + b
            case 1:
                let a = Int.random(in: 10...30)
                let b = Int.random(in: 1...a-1)
                qText = "\(a) - \(b)"
                ans = a - b
            default: break
            }
        } else if index < 80 {
            type = Int.random(in: 0...3)
            switch type {
            case 0:
                let a = Int.random(in: 15...99)
                let b = Int.random(in: 15...99)
                qText = "\(a) + \(b)"
                ans = a + b
            case 1:
                let a = Int.random(in: 20...99)
                let b = Int.random(in: 5...a-1)
                qText = "\(a) - \(b)"
                ans = a - b
            case 2:
                let a = Int.random(in: 2...10)
                let b = Int.random(in: 2...10)
                qText = "\(a) × \(b)"
                ans = a * b
            case 3:
                let b = Int.random(in: 2...10)
                let quotient = Int.random(in: 2...10)
                let a = b * quotient
                qText = "\(a) ÷ \(b)"
                ans = quotient
            default: break
            }
        } else {
            let roll = Int.random(in: 0...5)
            type = roll
            if roll == 3 { type = 2 }
            if roll >= 4 { type = 3 }
            
            switch type {
            case 0:
                let a = Int.random(in: 50...199)
                let b = Int.random(in: 50...199)
                qText = "\(a) + \(b)"
                ans = a + b
            case 1:
                let a = Int.random(in: 100...499)
                let b = Int.random(in: 20...99)
                qText = "\(a) - \(b)"
                ans = a - b
            case 2:
                let a = Int.random(in: 5...15)
                let b = Int.random(in: 5...15)
                qText = "\(a) × \(b)"
                ans = a * b
            case 3:
                let b = Int.random(in: 6...15)
                let quotient = Int.random(in: 6...15)
                let a = b * quotient
                qText = "\(a) ÷ \(b)"
                ans = quotient
            default: break
            }
        }
        
        if !used.contains(qText) {
            used.insert(qText)
            return MathProblem(questionText: qText, answer: ans)
        }
    }
}

func printHelp() {
    print("""
    \u{001B}[1;32mTRINITY\u{001B}[0m - System-Wide Website Blocker
    
    Usage:
      trinity block <domain>   - Add a website to the blocker immediately
      trinity unblock <domain> - Remove a website (only works if unlocked)
      trinity list             - View all currently blocked websites
      trinity status           - View daemon and lock status
      trinity unlock           - Begin the math challenge to unlock the system
      
    Management (Requires Sudo):
      sudo trinity start       - Boot the background daemon
      sudo trinity stop        - Tear down the background daemon (fails if locked)
    """)
}

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
    } catch {
        print("\u{001B}[31mError saving configuration: \(error)\u{001B}[0m")
    }
}

func getIsLocked() -> Bool {
    if let data = try? Data(contentsOf: TrinityPaths.stateURL),
       let state = try? JSONDecoder().decode(TrinityState.self, from: data) {
        return !state.isCurrentlyUnlocked
    }
    return true
}

func runBlock(domain: String) {
    let clean = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if clean.isEmpty { return }
    var config = loadConfig()
    if !config.blockedDomains.contains(clean) {
        config.blockedDomains.append(clean)
        saveConfig(config)
        print("\u{001B}[32mBlocked: \(clean)\u{001B}[0m")
    } else {
        print("\(clean) is already blocked.")
    }
}

func runUnblock(domain: String) {
    let locked = getIsLocked()
    if locked {
        print("\u{001B}[31mSystem is LOCKED. You cannot remove domains.\u{001B}[0m")
        print("Run `trinity unlock` in the terminal to gain temporary access.")
        exit(1)
    }
    
    let clean = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    var config = loadConfig()
    if let idx = config.blockedDomains.firstIndex(of: clean) {
        config.blockedDomains.remove(at: idx)
        saveConfig(config)
        print("\u{001B}[32mUnblocked: \(clean)\u{001B}[0m")
    } else {
        print("\(clean) is not in the blocklist.")
    }
}

func runList() {
    let config = loadConfig()
    if config.blockedDomains.isEmpty {
        print("Blocklist is currently empty.")
    } else {
        print("\u{001B}[1mBlocked Domains:\u{001B}[0m")
        for domain in config.blockedDomains {
            print("  - \(domain)")
        }
    }
}

func runStart() {
    if getuid() != 0 {
        print("\u{001B}[31mError: `trinity start` must be run with sudo.\u{001B}[0m")
        exit(1)
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    process.arguments = ["bootstrap", "system", "/Library/LaunchDaemons/com.trinity.daemon.plist"]
    do {
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            print("\u{001B}[32mDaemon started successfully.\u{001B}[0m")
        } else {
            print("\u{001B}[31mFailed to start daemon (maybe already running?).\u{001B}[0m")
        }
    } catch {
        print("Execution error: \(error)")
    }
}

func runStop() {
    if getuid() != 0 {
        print("\u{001B}[31mError: `trinity stop` must be run with sudo.\u{001B}[0m")
        exit(1)
    }
    if getIsLocked() {
        print("\u{001B}[31mError: System is LOCKED. You cannot stop the daemon right now.\u{001B}[0m")
        print("Run `trinity unlock` to gain temporary access.")
        exit(1)
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    process.arguments = ["bootout", "system/com.trinity.daemon"]
    do {
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus == 0 {
            print("\u{001B}[32mDaemon completely stopped.\u{001B}[0m")
        } else {
            print("\u{001B}[31mFailed to stop daemon (maybe it's not running?).\u{001B}[0m")
        }
    } catch {
        print("Execution error: \(error)")
    }
}

func printStatus() {
    print("\n\u{001B}[1m--- TRINITY STATUS ---\u{001B}[0m")
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
    process.arguments = ["print", "system/com.trinity.daemon"]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    try? process.run()
    process.waitUntilExit()
    
    let isRunning = process.terminationStatus == 0
    let daemonState = isRunning ? "Active & Installed" : "Not Installed"
    let color = isRunning ? "\u{001B}[32m" : "\u{001B}[31m"
    print("Daemon: \(color)\(daemonState)\u{001B}[0m")
    
    var isLocked = true
    var unlockDate: Date? = nil
    if let data = try? Data(contentsOf: TrinityPaths.stateURL),
       let state = try? JSONDecoder().decode(TrinityState.self, from: data) {
        if state.isCurrentlyUnlocked {
            isLocked = false
            unlockDate = state.unlockedUntil
        }
    }
    
    let configDomains = loadConfig().blockedDomains.count
    
    if isLocked {
        print("Enforcement: \u{001B}[31mLOCKED\u{001B}[0m")
        print("Restricted Sites: \(configDomains)")
    } else {
        print("Enforcement: \u{001B}[32mUNLOCKED\u{001B}[0m")
        if let expire = unlockDate {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            print("Grace period expires at: \(formatter.string(from: expire))")
        }
    }
    print("")
}

func startChallenge() {
    print("\u{001B}[2J\u{001B}[H", terminator: "")
    print("""
    \u{001B}[32m
      ████████╗██████╗ ██╗███╗   ██╗██╗████████╗██╗   ██╗
      ╚══██╔══╝██╔══██╗██║████╗  ██║██║╚══██╔══╝╚██╗ ██╔╝
         ██║   ██████╔╝██║██╔██╗ ██║██║   ██║    ╚████╔╝ 
         ██║   ██╔══██╗██║██║╚██╗██║██║   ██║     ╚██╔╝  
         ██║   ██║  ██║██║██║ ╚████║██║   ██║      ██║   
         ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝      ╚═╝   
    \u{001B}[0m
    """)
    print("\u{001B}[33mSystem Locked. You must complete 100 unique math problems to unlock.\u{001B}[0m")
    print("\u{001B}[90mIncorrect answers require a retry. Press CTRL+C to abort at any time.\u{001B}[0m\n")
    
    let totalProblems = 100
    var completed = 0
    var usedProblems = Set<String>()
    
    while completed < totalProblems {
        let problem = generateUniqueProblem(used: &usedProblems, index: completed)
        var answeredCorrectly = false
        
        let progressStr = String(format: "%03d", completed + 1)
        
        while !answeredCorrectly {
            print("\u{001B}[36m[\(progressStr)/\(totalProblems)]\u{001B}[0m \u{001B}[1m\(problem.questionText) = \u{001B}[0m", terminator: "")
            
            guard let input = readLine() else { exit(1) }
            if input.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            
            guard let parsedInput = Int(input.trimmingCharacters(in: .whitespaces)) else {
                print("\u{001B}[31m  ↳ Invalid input. Numbers only.\u{001B}[0m")
                continue
            }
            
            if parsedInput == problem.answer {
                answeredCorrectly = true
                completed += 1
                if completed < totalProblems {
                    print("\u{001B}[32m  ↳ Correct\u{001B}[0m")
                }
            } else {
                print("\u{001B}[31m  ↳ Incorrect. Try again.\u{001B}[0m")
            }
        }
    }
    
    print("\n\u{001B}[32m\u{001B}[1mChallenge Completed! 100/100 correct.\u{001B}[0m")
    print("\u{001B}[90mApplying unlock. Authentication is required to modify system settings.\u{001B}[0m")
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
    let executablePath = Bundle.main.executablePath ?? CommandLine.arguments[0]
    process.arguments = [executablePath, applyUnlockFlag]
    
    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        print("\u{001B}[31mFailed to escalate privileges: \(error)\u{001B}[0m")
    }
}

let args = CommandLine.arguments
if args.contains(applyUnlockFlag) {
    runApplyUnlock()
    exit(0)
}

if args.count > 1 {
    switch args[1] {
    case "block":
        if args.count > 2 {
            runBlock(domain: args[2])
        } else {
            print("\u{001B}[31mUsage: trinity block <domain>\u{001B}[0m")
        }
    case "unblock":
        if args.count > 2 {
            runUnblock(domain: args[2])
        } else {
            print("\u{001B}[31mUsage: trinity unblock <domain>\u{001B}[0m")
        }
    case "list":
        runList()
    case "start":
        runStart()
    case "stop":
        runStop()
    case "status":
        printStatus()
    case "unlock":
        if getIsLocked() {
            startChallenge()
        } else {
            print("\u{001B}[32mSystem is already unlocked. No math required!\u{001B}[0m")
        }
    case "help":
        printHelp()
    default:
        print("\u{001B}[31mUnknown command: \(args[1])\u{001B}[0m")
        printHelp()
    }
} else {
    printHelp()
}

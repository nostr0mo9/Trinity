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

func printStatus() {
    print("\n\u{001B}[1m--- TRINITY STATUS ---\u{001B}[0m")
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    process.arguments = ["-x", "TrinityDaemon"]
    let pipe = Pipe()
    process.standardOutput = pipe
    try? process.run()
    process.waitUntilExit()
    
    let isRunning = process.terminationStatus == 0
    let daemonState = isRunning ? "Active & Running" : "Not Running"
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
    
    var configDomains = 0
    if let configData = try? Data(contentsOf: TrinityPaths.configURL),
       let config = try? JSONDecoder().decode(TrinityConfig.self, from: configData) {
        configDomains = config.blockedDomains.count
    }
    
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
    case "unlock":
        var isLocked = true
        if let data = try? Data(contentsOf: TrinityPaths.stateURL),
           let state = try? JSONDecoder().decode(TrinityState.self, from: data) {
            isLocked = !state.isCurrentlyUnlocked
        }
        
        if isLocked {
            startChallenge()
        } else {
            print("\u{001B}[32mSystem is already unlocked. No math required!\u{001B}[0m")
        }
    case "status":
        printStatus()
    default:
        print("""
        Usage:
          trinity status    - Check daemon status and lock state
          trinity unlock    - Begin the unlock challenge
        """)
    }
} else {
    print("""
    Usage:
      trinity status    - Check daemon status and lock state
      trinity unlock    - Begin the unlock challenge
    """)
}

import Foundation
import CryptoKit

let hostsManager = HostsManager()

func hashFile(url: URL) -> String? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    let digest = SHA256.hash(data: data)
    return digest.compactMap { String(format: "%02x", $0) }.joined()
}

var persistentState: TrinityState? = nil
var persistentConfig: TrinityConfig? = nil

func runColdBootRecovery() {
    let fm = FileManager.default
    let stateMissing = !fm.fileExists(atPath: TrinityPaths.stateURL.path)
    
    if stateMissing {
        if let enforced = hostsManager.readCurrentEnforcement() {
            print("TrinityDaemon: Cold Boot Tamper Detected! Missing state.json, but /etc/hosts contains blocks. Reconstructing locked environmental state.")
            
            let reconstructedState = TrinityState(unlockedUntil: Date(timeIntervalSince1970: 0), configHash: nil, enforcedDomains: enforced)
            let reconstructedConfig = TrinityConfig(blockedDomains: enforced)
            
            persistentState = reconstructedState
            persistentConfig = reconstructedConfig
            
            try? fm.createDirectory(at: TrinityPaths.appSupportDir, withIntermediateDirectories: true, attributes: nil)
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            if let configData = try? encoder.encode(reconstructedConfig) {
                try? configData.write(to: TrinityPaths.configURL, options: .atomic)
            }
            if let stateData = try? encoder.encode(reconstructedState) {
                try? stateData.write(to: TrinityPaths.stateURL, options: .atomic)
            }
        }
    }
}

func enforcesLoop() {
    let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
    timer.schedule(deadline: .now(), repeating: 2.0)
    timer.setEventHandler {
        let fm = FileManager.default
        let stateMissing = !fm.fileExists(atPath: TrinityPaths.stateURL.path)
        let configMissing = !fm.fileExists(atPath: TrinityPaths.configURL.path)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        if (stateMissing || configMissing) && persistentState != nil {
            print("TrinityDaemon: Tamper attempt detected while daemon is running (files deleted). Restoring from RAM...")
            try? fm.createDirectory(at: TrinityPaths.appSupportDir, withIntermediateDirectories: true, attributes: nil)
            
            if stateMissing, let data = try? encoder.encode(persistentState) {
                try? data.write(to: TrinityPaths.stateURL, options: .atomic)
            }
            if configMissing, let data = try? encoder.encode(persistentConfig) {
                try? data.write(to: TrinityPaths.configURL, options: .atomic)
            }
        }
        
        var state: TrinityState
        if let stateData = try? Data(contentsOf: TrinityPaths.stateURL),
           let parsedState = try? JSONDecoder().decode(TrinityState.self, from: stateData) {
            state = parsedState
        } else if let ps = persistentState {
            state = ps
        } else {
            state = TrinityState()
        }
        
        let currentHash = hashFile(url: TrinityPaths.configURL)
        
        var config = TrinityConfig()
        if let configData = try? Data(contentsOf: TrinityPaths.configURL),
           let parsedConfig = try? JSONDecoder().decode(TrinityConfig.self, from: configData) {
            config = parsedConfig
        } else if let pc = persistentConfig {
            config = pc
        }
        
        let isConfigTampered = (state.configHash != nil && state.configHash != currentHash)
        let isUnlocked = state.isCurrentlyUnlocked && !isConfigTampered
        var stateNeedsSave = false
        
        if isUnlocked {
            hostsManager.apply(blockedDomains: [])
            let currentSet = Set(config.blockedDomains)
            let stateSet = Set(state.enforcedDomains ?? [])
            if currentSet != stateSet {
                state.enforcedDomains = Array(currentSet).sorted()
                stateNeedsSave = true
            }
        } else {
            let stateSet = Set(state.enforcedDomains ?? [])
            let configSet = Set(config.blockedDomains)
            
            if !stateSet.isSubset(of: configSet) {
                let unionSet = stateSet.union(configSet)
                config.blockedDomains = Array(unionSet).sorted()
                
                if let data = try? encoder.encode(config) {
                    try? data.write(to: TrinityPaths.configURL, options: .atomic)
                }
                
                state.enforcedDomains = config.blockedDomains
                stateNeedsSave = true
            } 
            else if configSet != stateSet {
                state.enforcedDomains = Array(configSet).sorted()
                stateNeedsSave = true
            }
            hostsManager.apply(blockedDomains: config.blockedDomains)
        }
        
        if stateNeedsSave {
            if let data = try? encoder.encode(state) {
                try? data.write(to: TrinityPaths.stateURL, options: .atomic)
                try? fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: TrinityPaths.stateURL.path)
            }
        }
        
        persistentState = state
        persistentConfig = config
    }
    timer.resume()
    RunLoop.main.run()
}

try? FileManager.default.createDirectory(at: TrinityPaths.appSupportDir, withIntermediateDirectories: true, attributes: nil)

print("TrinityDaemon started. Running cold boot checks...")
runColdBootRecovery()

print("TrinityDaemon: Polling every 2 seconds...")
enforcesLoop()

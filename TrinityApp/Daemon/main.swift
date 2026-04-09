import Foundation
import CryptoKit

let hostsManager = HostsManager()

func hashFile(url: URL) -> String? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    let digest = SHA256.hash(data: data)
    return digest.compactMap { String(format: "%02x", $0) }.joined()
}

func enforcesLoop() {
    let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
    timer.schedule(deadline: .now(), repeating: 2.0)
    timer.setEventHandler {
        var state: TrinityState
        if let stateData = try? Data(contentsOf: TrinityPaths.stateURL),
           let parsedState = try? JSONDecoder().decode(TrinityState.self, from: stateData) {
            state = parsedState
        } else {
            state = TrinityState()
        }
        
        let currentHash = hashFile(url: TrinityPaths.configURL)
        
        var config = TrinityConfig()
        if let configData = try? Data(contentsOf: TrinityPaths.configURL),
           let parsedConfig = try? JSONDecoder().decode(TrinityConfig.self, from: configData) {
            config = parsedConfig
        }
        
        let isConfigTampered = (state.configHash != nil && state.configHash != currentHash)
        let isUnlocked = state.isCurrentlyUnlocked && !isConfigTampered
        
        var stateNeedsSave = false
        
        if isUnlocked {
            hostsManager.apply(blockedDomains: [])
            
            let currentSet = Set(config.blockedDomains)
            let stateSet = Set(state.enforcedDomains ?? [])
            if currentSet != stateSet {
                state.enforcedDomains = Array(currentSet)
                stateNeedsSave = true
            }
        } else {
            let stateSet = Set(state.enforcedDomains ?? [])
            let configSet = Set(config.blockedDomains)
            
            if !stateSet.isSubset(of: configSet) {
                let unionSet = stateSet.union(configSet)
                config.blockedDomains = Array(unionSet).sorted()
                
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
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
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let data = try? encoder.encode(state) {
                try? data.write(to: TrinityPaths.stateURL, options: .atomic)
                try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: TrinityPaths.stateURL.path)
            }
        }
    }
    timer.resume()
    RunLoop.main.run()
}

try? FileManager.default.createDirectory(at: TrinityPaths.appSupportDir, withIntermediateDirectories: true, attributes: nil)

print("TrinityDaemon started. Polling every 2 seconds...")
enforcesLoop()

import Foundation
import NetworkExtension
import os.log

@objc(FilterDataProvider)
class FilterDataProvider: NEFilterDataProvider {
    
    private let log = OSLog(subsystem: "com.nostr0mo9.trinity.extension", category: "FilterData")
    
    // Shared App Group Path
    // Since App Groups require signing capabilities which must match the provisioning profile, 
    // we use a predictable app group path. 
    // If running in development without a profile, this might fail, but for production it's standard.
    private var sharedGroupURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nostr0mo9.trinity")
    }
    
    private var configURL: URL? {
        sharedGroupURL?.appendingPathComponent("config.json")
    }
    
    private var stateURL: URL? {
        sharedGroupURL?.appendingPathComponent("state.json")
    }
    
    // In-memory cache
    private var blockedDomains: [String] = []
    private var isCurrentlyUnlocked: Bool = false
    
    override func startFilter(completionHandler: @escaping (Error?) -> Void) {
        os_log("Trinity Content Filter starting up...", log: self.log, type: .info)
        reloadRules()
        completionHandler(nil)
    }
    
    override func stopFilter(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log("Trinity Content Filter stopping.", log: self.log, type: .info)
        completionHandler()
    }
    
    private func reloadRules() {
        // Read State
        if let stURL = stateURL,
           let data = try? Data(contentsOf: stURL) {
            // Very simple JSON parse for state
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let unlockedUntilRaw = json["unlockedUntil"] as? Double {
                let unlockedUntil = Date(timeIntervalSinceReferenceDate: unlockedUntilRaw)
                isCurrentlyUnlocked = Date() < unlockedUntil
            } else {
                isCurrentlyUnlocked = false
            }
        } else {
            isCurrentlyUnlocked = false // Fail closed
        }
        
        // Read Config
        if let cURL = configURL,
           let data = try? Data(contentsOf: cURL) {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let domains = json["blockedDomains"] as? [String] {
                self.blockedDomains = domains
            }
        }
    }
    
    override func handleNewFlow(_ flow: NEFilterFlow) -> NEFilterNewFlowVerdict {
        // Drop all routing to iCloud Private Relay to force standard routing visibility
        let privateRelayNodes = ["mask.icloud.com", "mask-h2.icloud.com"]
        
        guard let browserFlow = flow as? NEFilterBrowserFlow,
              let url = browserFlow.url,
              let host = url.host?.lowercased() else {
            
            // If it's a raw socket flow, evaluate the SNI/remote endpoint
            if let socketFlow = flow as? NEFilterSocketFlow,
               let remote = socketFlow.remoteEndpoint as? NWHostEndpoint {
                let remoteHost = remote.hostname.lowercased()
                if privateRelayNodes.contains(remoteHost) {
                    return .drop()
                }
                if evaluateHost(remoteHost) {
                    return .drop()
                }
            }
            return .allow()
        }
        
        if privateRelayNodes.contains(host) {
            return .drop()
        }
        
        if evaluateHost(host) {
            return .drop()
        }
        
        return .allow()
    }
    
    private func evaluateHost(_ host: String) -> Bool {
        reloadRules() // Ensure we have latest RAM state
        
        if isCurrentlyUnlocked { return false }
        
        for domain in blockedDomains {
            // Match exact domain or wildcard subdomain
            if host == domain || host.hasSuffix("." + domain) {
                os_log("Trinity actively severed routing for: %{public}@", log: self.log, type: .info, host)
                return true
            }
        }
        return false
    }
}

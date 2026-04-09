import Foundation

public class HostsManager {
    private let hostsPath = "/etc/hosts"
    private let startMarker = "# --- TRINITY START ---"
    private let endMarker = "# --- TRINITY END ---"
    
    public init() {}
    
    public func apply(blockedDomains: [String]) {
        do {
            let currentContent = try String(contentsOfFile: hostsPath, encoding: .utf8)
            let lines = currentContent.components(separatedBy: .newlines)
            
            var newLines: [String] = []
            var insideTrinityBlock = false
            
            for line in lines {
                if line == startMarker {
                    insideTrinityBlock = true
                    continue
                }
                if line == endMarker {
                    insideTrinityBlock = false
                    continue
                }
                if !insideTrinityBlock {
                    newLines.append(line)
                }
            }
            
            while newLines.last?.trimmingCharacters(in: .whitespaces).isEmpty == true {
                newLines.removeLast()
            }
            
            if !blockedDomains.isEmpty {
                newLines.append("")
                newLines.append(startMarker)
                newLines.append("# Do not edit manually. Trinity active.")
                
                for domain in blockedDomains {
                    let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleanDomain.isEmpty {
                        newLines.append("0.0.0.0 \(cleanDomain)")
                        newLines.append(":: \(cleanDomain)")
                        if !cleanDomain.starts(with: "www.") {
                            newLines.append("0.0.0.0 www.\(cleanDomain)")
                            newLines.append(":: www.\(cleanDomain)")
                        }
                    }
                }
                newLines.append(endMarker)
            }
            
            let resultString = newLines.joined(separator: "\n")
            
            if resultString != currentContent {
                try resultString.write(toFile: hostsPath, atomically: true, encoding: .utf8)
            }
            
        } catch {
            print("TrinityDaemon (HostsManager): Failed to apply hosts file changes. Error: \(error)")
        }
    }
}

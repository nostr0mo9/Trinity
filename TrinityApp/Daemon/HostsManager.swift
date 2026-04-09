import Foundation

public class HostsManager {
    private let hostsPath = "/etc/hosts"
    private let startMarker = "# --- TRINITY START ---"
    private let endMarker = "# --- TRINITY END ---"
    
    public init() {
        backupHostsIfNeeded()
    }
    
    public func backupHostsIfNeeded() {
        let fm = FileManager.default
        let backupPath = TrinityPaths.hostsBackupURL.path
        if !fm.fileExists(atPath: backupPath) {
            do {
                let currentContent = try String(contentsOfFile: hostsPath, encoding: .utf8)
                if !currentContent.contains(startMarker) {
                    try fm.createDirectory(at: TrinityPaths.protectedDir, withIntermediateDirectories: true, attributes: nil)
                    try currentContent.write(toFile: backupPath, atomically: true, encoding: .utf8)
                    try fm.setAttributes([.posixPermissions: 0o644], ofItemAtPath: backupPath)
                }
            } catch {
                print("TrinityDaemon: Failed to backup pristine hosts file. \(error)")
            }
        }
    }
    
    public func readCurrentEnforcement() -> [String]? {
        do {
            let currentContent = try String(contentsOfFile: hostsPath, encoding: .utf8)
            guard currentContent.contains(startMarker) else { return nil }
            
            let lines = currentContent.components(separatedBy: .newlines)
            var insideTrinityBlock = false
            var domains = Set<String>()
            
            for line in lines {
                if line == startMarker { insideTrinityBlock = true; continue }
                if line == endMarker { insideTrinityBlock = false; break }
                
                if insideTrinityBlock {
                    let clean = line.trimmingCharacters(in: .whitespaces)
                    if clean.hasPrefix("0.0.0.0 ") {
                        let domain = clean.replacingOccurrences(of: "0.0.0.0 ", with: "").trimmingCharacters(in: .whitespaces)
                        if !domain.isEmpty {
                            if domain.hasPrefix("www.") {
                                let root = String(domain.dropFirst(4))
                                domains.insert(root)
                            } else {
                                domains.insert(domain)
                            }
                        }
                    }
                }
            }
            return Array(domains).sorted()
        } catch {
            return nil
        }
    }
    
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

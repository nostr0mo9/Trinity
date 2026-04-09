import Foundation

public struct TrinityConfig: Codable {
    public var blockedDomains: [String]
    
    public init(blockedDomains: [String] = []) {
        self.blockedDomains = blockedDomains
    }
}

public struct TrinityState: Codable {
    public var unlockedUntil: Date?
    public var configHash: String?
    public var enforcedDomains: [String]?
    
    public init(unlockedUntil: Date? = nil, configHash: String? = nil, enforcedDomains: [String]? = nil) {
        self.unlockedUntil = unlockedUntil
        self.configHash = configHash
        self.enforcedDomains = enforcedDomains
    }
    
    public var isCurrentlyUnlocked: Bool {
        guard let unlockedUntil = unlockedUntil else { return false }
        return Date() < unlockedUntil
    }
}

public enum TrinityPaths {
    public static var appGroupDir: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nostr0mo9.trinity")
    }
    public static var appSupportDir: URL {
        appGroupDir ?? URL(fileURLWithPath: "/Users/Shared/Trinity")
    }
    public static var configURL: URL { appSupportDir.appendingPathComponent("config.json") }
    public static var stateURL: URL { appSupportDir.appendingPathComponent("state.json") }
    
    public static let protectedDir = URL(fileURLWithPath: "/Library/Application Support/Trinity")
    public static let hostsBackupURL = protectedDir.appendingPathComponent("hosts.backup")
}

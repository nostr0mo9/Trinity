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
    public static let appSupportDir = URL(fileURLWithPath: "/Users/Shared/Trinity")
    public static let configURL = appSupportDir.appendingPathComponent("config.json")
    public static let stateURL = appSupportDir.appendingPathComponent("state.json")
}

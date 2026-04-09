import SwiftUI
import ServiceManagement

@main
struct TrinityApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 400)
                .preferredColorScheme(.dark)
        }
    }
}

class AppState: ObservableObject {
    @Published var blockedDomains: [String] = []
    @Published var daemonStatus: SMAppService.Status = .notRegistered
    @Published var isLocked: Bool = true
    
    let daemonIdentifier = "com.trinity.daemon.plist"
    
    init() {
        loadConfig()
        checkStatusLoop()
    }
    
    func loadConfig() {
        if let data = try? Data(contentsOf: TrinityPaths.configURL),
           let config = try? JSONDecoder().decode(TrinityConfig.self, from: data) {
            self.blockedDomains = config.blockedDomains
        }
    }
    
    func saveConfig() {
        let config = TrinityConfig(blockedDomains: blockedDomains)
        do {
            try FileManager.default.createDirectory(at: TrinityPaths.appSupportDir, withIntermediateDirectories: true, attributes: nil)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(config)
            try data.write(to: TrinityPaths.configURL, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: TrinityPaths.configURL.path)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
    
    func checkStatusLoop() {
        checkAll()
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkAll()
        }
    }
    
    func checkAll() {
        checkDaemonStatus()
        checkLockState()
        loadConfig()
    }
    
    func checkDaemonStatus() {
        let service = SMAppService.daemon(plistName: daemonIdentifier)
        if daemonStatus != service.status {
            daemonStatus = service.status
        }
    }
    
    func checkLockState() {
        if let data = try? Data(contentsOf: TrinityPaths.stateURL),
           let state = try? JSONDecoder().decode(TrinityState.self, from: data) {
            let newlyLocked = !state.isCurrentlyUnlocked
            if self.isLocked != newlyLocked {
                self.isLocked = newlyLocked
            }
        } else {
            if !self.isLocked {
                self.isLocked = true
            }
        }
    }
    
    func registerDaemon() {
        let service = SMAppService.daemon(plistName: daemonIdentifier)
        do { try service.register(); checkAll() } catch { print("Failed to register: \(error)") }
    }
    
    func unregisterDaemon() {
        let service = SMAppService.daemon(plistName: daemonIdentifier)
        do { try service.unregister(); checkAll() } catch { print("Failed to unregister: \(error)") }
    }
    
    func addDomain(_ domain: String) {
        let trimmed = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmed.isEmpty && !blockedDomains.contains(trimmed) {
            blockedDomains.append(trimmed)
            saveConfig()
        }
    }
    
    func removeDomain(at offsets: IndexSet) {
        if isLocked { return }
        blockedDomains.remove(atOffsets: offsets)
        saveConfig()
    }
}

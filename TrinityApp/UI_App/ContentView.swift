import SwiftUI
import ServiceManagement

struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var newDomain: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("TRINITY")
                    .font(.system(size: 32, weight: .black, design: .monospaced))
                    .foregroundColor(.green)
                
                Spacer()
                
                if appState.isLocked {
                    Text("LOCKED")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(4)
                } else {
                    Text("UNLOCKED")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(4)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal)
            
            HStack {
                TextField("Enter domain (e.g. reddit.com)", text: $newDomain)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        appState.addDomain(newDomain)
                        newDomain = ""
                    }
                
                Button("Block") {
                    appState.addDomain(newDomain)
                    newDomain = ""
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)
            
            if appState.isLocked {
                Text("You can add new sites, but must use `trinity unlock` in Terminal to remove them.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
            
            List {
                ForEach(appState.blockedDomains, id: \.self) { domain in
                    Text(domain)
                        .font(.system(.body, design: .monospaced))
                }
                .onDelete(perform: appState.isLocked ? nil : appState.removeDomain)
            }
            .border(Color.gray.opacity(0.3))
            .padding(.horizontal)
            
            HStack {
                Text("Daemon Status:")
                    .font(.headline)
                
                Text(statusText(for: appState.daemonStatus))
                    .foregroundColor(statusColor(for: appState.daemonStatus))
                    .fontWeight(.bold)
                
                Spacer()
                
                if appState.daemonStatus == .enabled {
                    Button("Stop Blocker") {
                        appState.unregisterDaemon()
                    }
                    .disabled(appState.isLocked)
                } else {
                    Button("Start Blocker") {
                        appState.registerDaemon()
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.5))
        }
        .background(Color.black)
        .foregroundColor(.white)
        .onAppear {
            appState.checkAll()
        }
    }
    
    func statusText(for status: SMAppService.Status) -> String {
        switch status {
        case .enabled: return "Enabled (Active)"
        case .requiresApproval: return "Requires Approval in System Settings"
        case .notFound: return "Not Found"
        default: return "Not Running"
        }
    }
    
    func statusColor(for status: SMAppService.Status) -> Color {
        switch status {
        case .enabled: return .green
        case .requiresApproval: return .orange
        default: return .red
        }
    }
}

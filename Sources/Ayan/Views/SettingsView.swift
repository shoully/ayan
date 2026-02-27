import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("retentionDays") private var retentionDays = 0 // 0 means Forever
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.title2).bold()
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data Management")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Picker("Keep History For:", selection: $retentionDays) {
                            Text("Forever").tag(0)
                            Text("7 Days").tag(7)
                            Text("30 Days").tag(30)
                        }
                        .pickerStyle(.menu)
                        
                        Button(action: performCleanup) {
                            Label("Clean Up Old Entries Now", systemImage: "sparkles")
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Database")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            
                        Text("Ayan stores its data in a local SQLite file.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        let dbPath = "/Users/shoully/Library/Application Support/default.store"
                        
                        Text(dbPath)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .padding(8)
                            .background(Color.black.opacity(0.2))
                            .cornerRadius(6)
                            .textSelection(.enabled)
                        
                        Button("Show in Finder") {
                            NSWorkspace.shared.selectFile(dbPath, inFileViewerRootedAtPath: "")
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
    }
    
    private func performCleanup() {
        let days = retentionDays
        guard days > 0 else { return }
        
        if let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) {
            try? modelContext.delete(model: TimeEntry.self, where: #Predicate { $0.start < cutoff })
        }
    }
}

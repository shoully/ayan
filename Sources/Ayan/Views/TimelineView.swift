import SwiftUI
import SwiftData

struct TimelineView: View {
    var entries: [TimeEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Daily Timeline")
                    .font(.title2).bold()
                Spacer()
                Button(action: exportToCSV) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.plain)
                .help("Export to CSV")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(entries) { entry in
                        HStack(alignment: .top, spacing: 12) {
                            VStack {
                                Circle()
                                    .fill(Color(hex: entry.projectColorHex ?? "") ?? (entry.isDrift ? Color.gray.opacity(0.5) : Color.gray.opacity(0.3)))
                                    .frame(width: 10, height: 10)
                                if entries.last != entry {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(width: 1)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(entry.start.formatted(date: .omitted, time: .shortened))
                                        .font(.caption).foregroundStyle(.secondary)
                                    
                                    if let end = entry.end {
                                        Text("→ \(end.formatted(date: .omitted, time: .shortened))")
                                            .font(.caption).foregroundStyle(.secondary)
                                        
                                        Text("(\(durationString(from: entry.start, to: end)))")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    } else {
                                        Text("(Active)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Text(entry.projectName ?? (entry.isDrift ? "Drift" : "Uncategorized"))
                                    .fontWeight(.semibold)
                                
                                HStack(spacing: 8) {
                                    if let type = entry.activityType {
                                        Text(type)
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.primary.opacity(0.1))
                                            .cornerRadius(3)
                                    }
                                    
                                    Text(entry.context.replacingOccurrences(of: "[\(entry.appName)]", with: "").trimmingCharacters(in: .whitespaces))
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
        }
        .padding(.top)
    }
    
    private func durationString(from start: Date, to end: Date) -> String {
        let diff = Int(end.timeIntervalSince(start))
        let minutes = diff / 60
        if minutes == 0 { return "\(diff)s" }
        return "\(minutes)m"
    }

    private func exportToCSV() {
        let header = "App,Context,Project,Activity,Start,End,Duration(s)\\n"
        let rows = entries.map { entry in
            let app = entry.appName
            let cleanContext = entry.context.replacingOccurrences(of: "[\(entry.appName)]", with: "").trimmingCharacters(in: .whitespaces)
            let project = entry.projectName ?? (entry.isDrift ? "Drift" : "None")
            let activity = entry.activityType ?? "Other"
            let start = entry.start.formatted()
            let end = entry.end?.formatted() ?? "Active"
            let duration = entry.duration
            
            // CSV escaping
            let escApp = app.replacingOccurrences(of: "\"", with: "\"\"")
            let escContext = cleanContext.replacingOccurrences(of: "\"", with: "\"\"")
            let escProject = project.replacingOccurrences(of: "\"", with: "\"\"")
            let escActivity = activity.replacingOccurrences(of: "\"", with: "\"\"")
            
            return "\"\(escApp)\",\"\(escContext)\",\"\(escProject)\",\"\(escActivity)\",\"\(start)\",\"\(end)\",\(duration)"
        }.joined(separator: "\n")
        
        let content = header + rows
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "Ayan_Narrative_Export.csv"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? content.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

import SwiftUI
import SwiftData

struct TimelineView: View {
    var entries: [TimeEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(entries) { entry in
                        TimelineRow(entry: entry, isLast: entries.last == entry)
                        
                        if entries.last != entry {
                            Divider().padding(.leading, 44).opacity(0.3)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct TimelineRow: View {
    let entry: TimeEntry
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color(hex: entry.projectColorHex ?? "") ?? (entry.isDrift ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)))
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
            .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(entry.projectName ?? (entry.isDrift ? "Drift" : "Uncategorized"))
                        .font(.system(size: 13, weight: .semibold))
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(entry.start.formatted(date: .omitted, time: .shortened))
                        if let end = entry.end {
                            Text("→")
                            Text(end.formatted(date: .omitted, time: .shortened))
                        }
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                }
                
                HStack(spacing: 8) {
                    if let type = entry.activityType {
                        Text(type.uppercased())
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(.accent)
                            .cornerRadius(3)
                    }
                    
                    Text(entry.context.replacingOccurrences(of: "[\(entry.appName)]", with: "").trimmingCharacters(in: .whitespaces))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .hoverEffect()
    }
}

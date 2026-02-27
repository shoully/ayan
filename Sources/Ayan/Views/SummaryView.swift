import SwiftUI
import SwiftData

struct SummaryView: View {
    var entries: [TimeEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Activity Summary")
                .font(.title2).bold()
                .padding([.horizontal, .top])
            
            let grouped = Dictionary(grouping: entries, by: { $0.appName })
            let totalSeconds = grouped.values.flatMap { $0 }.reduce(0) { $0 + $1.duration }
            
            List {
                ForEach(grouped.keys.sorted(), id: \.self) { appName in
                    let appEntries = grouped[appName] ?? []
                    let appTotalSeconds = appEntries.reduce(0) { $0 + $1.duration }
                    
                    DisclosureGroup {
                        ForEach(appEntries) { entry in
                            HStack {
                                Circle()
                                    .fill(Color(hex: entry.projectColorHex ?? "") ?? .gray.opacity(0.5))
                                    .frame(width: 8, height: 8)
                                Text(entry.context.replacingOccurrences(of: "[\(appName)]", with: "").trimmingCharacters(in: .whitespaces))
                                Spacer()
                                Text(formatDuration(seconds: entry.duration))
                            }
                            .font(.callout)
                            .padding(.leading)
                            .foregroundStyle(.secondary)
                        }
                    } label: {
                        HStack {
                            Text(appName)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(formatDuration(seconds: appTotalSeconds))
                                .foregroundStyle(.secondary)
                            if totalSeconds > 0 {
                                ProgressView(value: Double(appTotalSeconds), total: Double(totalSeconds))
                                    .frame(width: 50)
                            }
                        }
                        .font(.headline)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
    
    private func formatDuration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}

import SwiftUI
import SwiftData

struct SummaryView: View {
    var entries: [TimeEntry]
    
    var body: some View {
        let grouped = Dictionary(grouping: entries, by: { $0.appName })
        let totalSeconds = grouped.values.flatMap { $0 }.reduce(0) { $0 + $1.duration }
        
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text("Activity Summary")
                    .font(.title2).bold()
                Spacer()
                Text("Total: \(formatDuration(seconds: totalSeconds))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 12)
            
            ScrollView {
                VStack(spacing: 12) {
                    let sortedApps = grouped.keys.sorted { app1, app2 in
                        let duration1 = grouped[app1]?.reduce(0) { $0 + $1.duration } ?? 0
                        let duration2 = grouped[app2]?.reduce(0) { $0 + $1.duration } ?? 0
                        return duration1 > duration2
                    }
                    
                    ForEach(sortedApps, id: \.self) { appName in
                        let appEntries = grouped[appName] ?? []
                        let appTotalSeconds = appEntries.reduce(0) { $0 + $1.duration }
                        
                        AppSummaryCard(
                            appName: appName,
                            entries: appEntries,
                            totalAppSeconds: appTotalSeconds,
                            totalOverallSeconds: totalSeconds
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}

struct AppSummaryCard: View {
    let appName: String
    let entries: [TimeEntry]
    let totalAppSeconds: Int
    let totalOverallSeconds: Int
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.1))
                                
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.8))
                                    .frame(width: max(0, geo.size.width * CGFloat(totalAppSeconds) / CGFloat(max(1, totalOverallSeconds))))
                            }
                        }
                        .frame(height: 4)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatDuration(seconds: totalAppSeconds))
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        
                        let percentage = Double(totalAppSeconds) / Double(max(1, totalOverallSeconds))
                        Text(String(format: "%.1f%%", percentage * 100))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .padding(.leading, 4)
                }
                .padding()
        .background(Color(red: 0.15, green: 0.15, blue: 0.16)) // Solid opaque color
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
    }
}

fileprivate func formatDuration(seconds: Int) -> String {
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

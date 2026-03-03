import SwiftUI
import SwiftData

struct SummaryView: View {
    var entries: [TimeEntry]
    
    var body: some View {
        let grouped = Dictionary(grouping: entries, by: { $0.appName })
        let totalSeconds = grouped.values.flatMap { $0 }.reduce(0) { $0 + $1.duration }
        
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    let sortedApps = grouped.keys.sorted { app1, app2 in
                        let duration1 = grouped[app1]?.reduce(0) { $0 + $1.duration } ?? 0
                        let duration2 = grouped[app2]?.reduce(0) { $0 + $1.duration } ?? 0
                        return duration1 > duration2
                    }
                    
                    ForEach(sortedApps, id: \.self) { appName in
                        let appEntries = grouped[appName] ?? []
                        let appTotalSeconds = appEntries.reduce(0) { $0 + $1.duration }
                        
                        AppSummaryRow(
                            appName: appName,
                            entries: appEntries,
                            totalAppSeconds: appTotalSeconds,
                            totalOverallSeconds: totalSeconds
                        )
                        
                        if appName != sortedApps.last {
                            Divider().padding(.leading, 16).opacity(0.3)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct AppSummaryRow: View {
    let appName: String
    let entries: [TimeEntry]
    let totalAppSeconds: Int
    let totalOverallSeconds: Int
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.primary.opacity(0.05))
                                
                                Capsule()
                                    .fill(Color.accentColor.opacity(0.6))
                                    .frame(width: max(0, geo.size.width * CGFloat(totalAppSeconds) / CGFloat(max(1, totalOverallSeconds))))
                            }
                        }
                        .frame(height: 3)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatDuration(seconds: totalAppSeconds))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        let percentage = Double(totalAppSeconds) / Double(max(1, totalOverallSeconds))
                        Text(String(format: "%.1f%%", percentage * 100))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .hoverEffect()
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    let groupedByContext = Dictionary(grouping: entries) { entry -> String in
                        let context = entry.context.replacingOccurrences(of: "[\(entry.appName)]", with: "").trimmingCharacters(in: .whitespaces)
                        return context.isEmpty ? "Active" : context
                    }
                    
                    let sortedContexts = groupedByContext.keys.sorted { c1, c2 in
                        let d1 = groupedByContext[c1]?.reduce(0) { $0 + $1.duration } ?? 0
                        let d2 = groupedByContext[c2]?.reduce(0) { $0 + $1.duration } ?? 0
                        return d1 > d2
                    }
                    
                    ForEach(sortedContexts, id: \.self) { context in
                        let contextEntries = groupedByContext[context] ?? []
                        let contextDuration = contextEntries.reduce(0) { $0 + $1.duration }
                        let projectColorHex = contextEntries.first(where: { $0.projectColorHex != nil })?.projectColorHex
                        
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Color(hex: projectColorHex ?? "") ?? .gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                                .padding(.top, 5)
                            
                            Text(context)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer(minLength: 16)
                            
                            Text(formatDuration(seconds: contextDuration))
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.leading, 32)
                        .padding(.trailing, 16)
                        .padding(.vertical, 6)
                    }
                }
                .padding(.bottom, 8)
                .background(Color.primary.opacity(0.02))
            }
        }
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

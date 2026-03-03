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
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
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
                                .fill(Color(hex: projectColorHex ?? "") ?? .gray.opacity(0.5))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            Text(context)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Spacer(minLength: 16)
                            
                            Text(formatDuration(seconds: contextDuration))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        if context != sortedContexts.last {
                            Divider().padding(.leading, 32)
                        }
                    }
                }
                .background(Color.primary.opacity(0.02))
            }
        }
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

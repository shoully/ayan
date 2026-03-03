import SwiftUI
import SwiftData

struct NarrativeView: View {
    @Query(sort: \TimeEntry.start, order: .reverse) var entries: [TimeEntry]
    var state: PopoverState
    @State private var selectedTab = 0
    private let cornerRadius: CGFloat = 12

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.13)) // Standard Dark Mode background
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)

            VStack(spacing: 0) {
                HStack {
                    Picker("", selection: $selectedTab) {
                        Label("Timeline", systemImage: "clock").tag(0)
                        Label("Summary", systemImage: "chart.pie").tag(1)
                        Label("Projects", systemImage: "briefcase").tag(2)
                        Label("Keywords", systemImage: "tag").tag(3)
                        Label("Settings", systemImage: "gearshape").tag(4)
                    }
                    .labelStyle(.iconOnly)
                    .pickerStyle(.segmented)
                    
                    Spacer()
                    
                    Button {
                        state.isPinned.toggle()
                    } label: {
                        Image(systemName: state.isPinned ? "pin.fill" : "pin")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(state.isPinned ? Color.accentColor : Color.secondary)
                    
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 10)

                if selectedTab == 0 {
                    TimelineView(entries: entries)
                } else if selectedTab == 1 {
                    SummaryView(entries: entries)
                } else if selectedTab == 2 {
                    ProjectsView(entries: entries)
                } else if selectedTab == 3 {
                    KeywordsView()
                } else {
                    SettingsView()
                }
            }
        }
        .frame(width: 380, height: 550)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}

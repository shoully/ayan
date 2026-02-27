import SwiftUI
import SwiftData

struct NarrativeView: View {
    @Query(sort: \TimeEntry.start, order: .reverse) var entries: [TimeEntry]
    var state: PopoverState
    @State private var selectedTab = 0
    private let popoverNubSize: CGFloat = 12

    var body: some View {
        ZStack {
            PopoverShape(nubSize: popoverNubSize)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

            VStack(spacing: 0) {
                HStack {
                    Picker("", selection: $selectedTab) {
                        Label("Timeline", systemImage: "chart.bar.doc.horizontal").tag(0)
                        Label("Summary", systemImage: "list.bullet.indent").tag(1)
                        Label("Projects", systemImage: "folder").tag(2)
                        Label("Keywords", systemImage: "text.magnifyingglass").tag(3)
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
                    .help(state.isPinned ? "Unpin Window" : "Pin Window")
                    
                }
                .padding(.horizontal)
                .padding(.top, popoverNubSize + 6)
                .padding(.bottom, 6)

                if selectedTab == 0 {
                    TimelineView(entries: entries)
                } else if selectedTab == 1 {
                    SummaryView(entries: entries)
                } else if selectedTab == 2 {
                    ProjectsView()
                } else if selectedTab == 3 {
                    KeywordsView()
                } else {
                    SettingsView()
                }
            }
        }
        .frame(width: 380, height: 550 + popoverNubSize)
        .ignoresSafeArea()
    }
}

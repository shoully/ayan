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
                .fill(Color(red: 0.12, green: 0.12, blue: 0.13).opacity(0.95)) // 5% transparent
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1.0) // Pronounced glass-like grey stroke
                )
                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)

            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Group {
                        tabButton(icon: "clock", index: 0)
                        tabButton(icon: "chart.pie", index: 1)
                        tabButton(icon: "briefcase", index: 2)
                        tabButton(icon: "tag", index: 3)
                        tabButton(icon: "gearshape", index: 4)
                    }
                    
                    Spacer()
                    
                    Button {
                        state.isPinned.toggle()
                    } label: {
                        Image(systemName: state.isPinned ? "pin.fill" : "pin")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(state.isPinned ? Color.accentColor : Color.secondary)
                    .focusable(false)
                    
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

    private func tabButton(icon: String, index: Int) -> some View {
        Button {
            selectedTab = index
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(selectedTab == index ? Color.accentColor : .secondary)
                .padding(4)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

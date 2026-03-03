import SwiftUI
import SwiftData

struct NarrativeView: View {
    @Query(sort: \TimeEntry.start, order: .reverse) var entries: [TimeEntry]
    var state: PopoverState
    @State private var selectedTab = 0
    private let popoverNubSize: CGFloat = 12

    var body: some View {
        ZStack {
            // Backdrop with Vibrancy
            VisualEffectView(material: .menu, blendingMode: .behindWindow)
                .clipShape(PopoverShape(nubSize: popoverNubSize))
                .overlay(
                    PopoverShape(nubSize: popoverNubSize)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.25), radius: 10, y: 5)

            VStack(spacing: 0) {
                // Header (Herd Style)
                HStack(spacing: 12) {
                    Image(systemName: "timer.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.accent)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Ayan")
                            .font(.headline)
                        Text("v1.0.0 • Professional Narrative")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        state.isPinned.toggle()
                    } label: {
                        Image(systemName: state.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(state.isPinned ? Color.accentColor : Color.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, popoverNubSize + 12)
                .padding(.bottom, 12)

                Divider().opacity(0.5)

                // Navigation (Cleaner than Picker)
                HStack(spacing: 0) {
                    navItem(title: "Timeline", icon: "clock", index: 0)
                    navItem(title: "Summary", icon: "chart.pie", index: 1)
                    navItem(title: "Projects", icon: "briefcase", index: 2)
                    navItem(title: "Keywords", icon: "tag", index: 3)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)

                Divider().opacity(0.5)

                // Main Content
                VStack(spacing: 0) {
                    if selectedTab == 0 {
                        TimelineView(entries: entries)
                    } else if selectedTab == 1 {
                        SummaryView(entries: entries)
                    } else if selectedTab == 2 {
                        ProjectsView(entries: entries)
                    } else if selectedTab == 3 {
                        KeywordsView()
                    }
                }
                .frame(maxHeight: .infinity)

                Divider().opacity(0.5)

                // Footer (Menu Style)
                VStack(spacing: 0) {
                    footerItem(title: "Settings", icon: "gearshape", shortcut: "⌘ ,") {
                        selectedTab = 4 // Settings tab index or just show settings view
                    }
                    
                    footerItem(title: "Quit Ayan", icon: "power", shortcut: "⌘ Q", isDestructive: true) {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
            }
            
            // Overlay Settings View when selected (Slide up?)
            if selectedTab == 4 {
                VisualEffectView(material: .menu, blendingMode: .behindWindow)
                    .transition(.move(edge: .bottom))
                    .overlay(
                        VStack(spacing: 0) {
                            HStack {
                                Button("Back") {
                                    withAnimation(.spring()) {
                                        selectedTab = 0
                                    }
                                }
                                .buttonStyle(.link)
                                .padding()
                                Spacer()
                            }
                            SettingsView()
                        }
                    )
                    .clipShape(PopoverShape(nubSize: popoverNubSize))
                    .zIndex(10)
            }
        }
        .frame(width: 380, height: 600 + popoverNubSize)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private func navItem(title: String, icon: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selectedTab == index ? Color.accentColor.opacity(0.15) : Color.clear)
            .foregroundStyle(selectedTab == index ? .accent : .secondary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func footerItem(title: String, icon: String, shortcut: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.system(size: 13))
                Spacer()
                Text(shortcut)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .foregroundStyle(isDestructive ? .red : .primary)
        }
        .buttonStyle(.plain)
        .hoverEffect()
    }
}

extension View {
    func hoverEffect() -> some View {
        self.modifier(HoverModifier())
    }
}

struct HoverModifier: ViewModifier {
    @State private var isHovered = false
    func body(content: Content) -> some View {
        content
            .background(isHovered ? Color.primary.opacity(0.08) : Color.clear)
            .cornerRadius(6)
            .onHover { isHovered = $0 }
    }
}

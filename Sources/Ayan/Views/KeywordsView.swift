import SwiftUI
import SwiftData

struct KeywordsView: View {
    @AppStorage("customCodeRoots") private var codeRootsString = "apps, Sites, Code, Developer, projects, work, github, repositories, src, lab"
    @AppStorage("customServiceNames") private var serviceNamesString = "cPanel, Vercel, Netlify, Heroku, Supabase, Firebase, Linear, Slack, Discord"
    @AppStorage("customBlacklist") private var blacklistedWordsString = "google, github, localhost, 127, apple, microsoft, amazon, facebook, twitter, linkedin, Home, Index, Login, Dashboard, Untitled, Google Search, Privacy Policy, Terms of Service, node, python, bash, zsh, docker, root, admin, main, master, develop, debug, release, documents, desktop, downloads, library, applications, users, pictures, movies, public, shared, bin, etc, var, tmp"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    
                    KeywordSection(
                        title: "Code Directory Roots",
                        subtitle: "Ayan detects projects when it sees these folders in your file paths (e.g., in iTerm or VSCode).",
                        keywords: $codeRootsString,
                        icon: "folder.badge.gearshape"
                    )
                    
                    KeywordSection(
                        title: "SaaS & Service Names",
                        subtitle: "Common web services Ayan should recognize as their own projects.",
                        keywords: $serviceNamesString,
                        icon: "cloud"
                    )
                    
                    KeywordSection(
                        title: "Ignored Noise (Blacklist)",
                        subtitle: "Generic words that should NEVER be turned into an auto-detected project.",
                        keywords: $blacklistedWordsString,
                        icon: "hand.raised.slash"
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
        }
    }
}

struct KeywordSection: View {
    let title: String
    let subtitle: String
    @Binding var keywords: String
    let icon: String
    
    @State private var newKeyword = ""
    @State private var isRawEdit = false
    
    var keywordList: [String] {
        keywords.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Button(isRawEdit ? "Done" : "Bulk Edit") {
                    withAnimation { isRawEdit.toggle() }
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(Color.accentColor)
            }
            
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if isRawEdit {
                TextEditor(text: $keywords)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 100)
                    .padding(4)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
            } else {
                // Tag Cloud
                FlowLayout(spacing: 8) {
                    ForEach(keywordList, id: \.self) { keyword in
                        TagView(text: keyword) {
                            removeKeyword(keyword)
                        }
                    }
                }
                
                // Add New Keyword
                HStack {
                    TextField("Add new (comma separated)...", text: $newKeyword)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(6)
                        .onSubmit { addKeyword() }
                    
                    Button(action: addKeyword) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(newKeyword.isEmpty)
                }
                .padding(.top, 4)
            }
        }
    }
    
    private func addKeyword() {
        let input = newKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        let newItems = input.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var current = keywordList
        for item in newItems {
            if !current.contains(item) {
                current.append(item)
            }
        }
        
        keywords = current.joined(separator: ", ")
        newKeyword = ""
    }
    
    private func removeKeyword(_ keyword: String) {
        let updated = keywordList.filter { $0 != keyword }
        keywords = updated.joined(separator: ", ")
    }
}

struct TagView: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.system(size: 11, weight: .medium))
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.1))
        .cornerRadius(12)
    }
}

// A simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var width: CGFloat = 0
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for size in sizes {
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            width = max(width, currentX)
        }
        
        height = currentY + lineHeight
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

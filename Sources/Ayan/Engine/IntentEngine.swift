import Foundation
import SwiftData

@MainActor
class IntentEngine {
    private var modelContext: ModelContext
    private var activeEntry: TimeEntry?
    
    // Memory for Project Stickiness (Affinity)
    private var lastHighSignalProject: Project?
    private var lastHighSignalTime: Date = Date.distantPast
    private let affinityWindow: TimeInterval = 600 // 10 minutes stickiness

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Processes a new context string from the Watcher
    func process(context: String) -> Project? {
        // 1. Hierarchical Detection
        var matchedProject: Project? = nil
        let appName = extractAppName(from: context)
        
        // Priority 1: User-assigned fingerprints (Manual)
        matchedProject = findProjectByFingerprint(for: context)
        
        // Priority 2: High-Signal IDE/Tool Context (VS Code, Xcode, iTerm path)
        if matchedProject == nil {
            matchedProject = detectFromHighSignalApps(context: context, appName: appName)
        }
        
        // Priority 3: Deep SaaS Parsing (Jira, Figma, Linear, etc.)
        if matchedProject == nil {
            matchedProject = detectFromSaaS(context: context)
        }
        
        // Priority 4: Smart Affinity (Stickiness)
        // If we are in a "Tool" or "Generic" app, inherit the last high-signal project
        if matchedProject == nil {
            if isToolApp(appName) || isGenericContext(context) {
                if Date().timeIntervalSince(lastHighSignalTime) < affinityWindow {
                    matchedProject = lastHighSignalProject
                }
            }
        }
        
        // Update High-Signal memory if we found a "real" project match
        if let found = matchedProject, !isToolApp(appName) {
            lastHighSignalProject = found
            lastHighSignalTime = Date()
        }
        
        // 3. Handle entry stability and state changes
        var newStartTime = Date()
        
        if let current = active_entry_access() {
            let projectsMatch = current.projectName == matchedProject?.name
            
            if projectsMatch || isSimilar(current.context, context) {
                current.context = context
                if current.isDrift && matchedProject != nil {
                    current.isDrift = false
                    current.projectName = matchedProject!.name
                    current.projectColorHex = matchedProject!.colorHex
                }
                return matchedProject
            }
            
            current.end = Date()
            let duration = Int(Date().timeIntervalSince(current.start))
            
            if duration < 15 {
                newStartTime = current.start
                modelContext.delete(current)
            }
        }
        
        // 4. Create a new entry
        let activity = categorizeActivity(appName: appName, context: context)
        let newEntry = TimeEntry(
            start: newStartTime,
            context: context,
            isDrift: matchedProject == nil,
            project: matchedProject,
            activityType: activity
        )
        modelContext.insert(newEntry)
        activeEntry = newEntry
        
        return matchedProject
    }
    
    // --- CATEGORIZATION ---
    
    private func categorizeActivity(appName: String, context: String) -> String {
        let coding = ["Visual Studio Code", "Xcode", "Sublime Text", "iTerm2", "Terminal"]
        if coding.contains(appName) { return "Coding" }
        
        let comms = ["Slack", "Discord", "Zoom", "Microsoft Teams", "Mail", "Outlook", "WhatsApp", "Telegram"]
        if comms.contains(appName) { return "Communication" }
        
        let design = ["Figma", "Adobe", "Photoshop", "Illustrator", "Canva"]
        if design.contains(appName) { return "Design" }
        
        let docs = ["Pages", "Numbers", "Keynote", "Word", "Excel", "PowerPoint", "Notion", "Linear"]
        if docs.contains(appName) || context.contains("linear.app") { return "Planning" }
        
        return "Research"
    }
    
    // --- DETECTION LOGIC ---

    private func detectFromHighSignalApps(context: String, appName: String) -> Project? {
        let defaults = UserDefaults.standard
        let codeRootsStr = defaults.string(forKey: "customCodeRoots") ?? "apps, Sites, Code, Developer, projects, work, github, repositories, src, lab"
        let codeRoots = codeRootsStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        // VS Code / IDE Pattern: "Filename — ProjectName"
        if ["Visual Studio Code", "Sublime Text", "Xcode"].contains(appName) {
            let separators = [" — ", " - ", " | "]
            for sep in separators {
                let parts = context.components(separatedBy: sep)
                if parts.count >= 2 {
                    let potentialProject = parts[parts.count - 2].trimmingCharacters(in: .whitespaces)
                    if potentialProject.count > 2 && !isBlacklisted(potentialProject) {
                        return getOrCreateProject(named: potentialProject)
                    }
                }
            }
        }
        
        // Path Pattern (Terminal, Finder)
        for root in codeRoots {
            let pathPattern = "(?i)(?:/|\(root)/|~\(root)/| \(root)/|\(root)/)([^/\\s:\\]]+)"
            if let name = matchFirstGroup(in: context, pattern: pathPattern) {
                if !isBlacklisted(name) {
                    return getOrCreateProject(named: name)
                }
            }
        }
        
        return nil
    }
    
    private func detectFromSaaS(context: String) -> Project? {
        // Jira: company.atlassian.net/browse/PROJ-123
        if let jiraMatch = matchFirstGroup(in: context, pattern: "atlassian\\.net/browse/([A-Z0-9]+)-") {
            return getOrCreateProject(named: jiraMatch)
        }
        
        // Figma: figma.com/file/ID/Project-Name
        if let figmaMatch = matchFirstGroup(in: context, pattern: "figma\\.com/file/[^/]+/([^/\\s\\?#]+)") {
            let clean = figmaMatch.replacingOccurrences(of: "-", with: " ").replacingOccurrences(of: "_", with: " ")
            return getOrCreateProject(named: clean)
        }
        
        // Linear: linear.app/team/issue/PROJ-123
        if let linearMatch = matchFirstGroup(in: context, pattern: "linear\\.app/[^/]+/[^/]+/([A-Z0-9]+)-") {
            return getOrCreateProject(named: linearMatch)
        }

        // Generic Domain Detection
        let urlPattern = "(?i)(?:https?://)?(?:www\\.)?([^/\\s:\\?#\\(\\)]+)"
        if let domain = matchFirstGroup(in: context, pattern: urlPattern) {
            let parts = domain.components(separatedBy: ".")
            if parts.count >= 2 {
                let brand = parts[max(0, parts.count - 2)]
                if !isBlacklisted(brand) && brand.count > 3 {
                    return getOrCreateProject(named: brand)
                }
            }
        }
        
        return nil
    }
    
    private func isToolApp(_ appName: String) -> Bool {
        let tools = ["Slack", "Discord", "Zoom", "Microsoft Teams", "Mail", "Outlook", "Calendar", "Notes", "Spotify", "Music", "System Settings"]
        return tools.contains { appName.contains($0) }
    }
    
    private func isGenericContext(_ context: String) -> Bool {
        let generic = ["Google Search", "New Tab", "Dashboard", "Home", "Inbox"]
        return generic.contains { context.contains($0) }
    }
    
    private func isBlacklisted(_ word: String) -> Bool {
        let defaults = UserDefaults.standard
        let blacklistStr = defaults.string(forKey: "customBlacklist") ?? "google, github, localhost, 127, apple, microsoft, amazon, facebook, twitter, linkedin, node, python, bash, zsh, docker"
        let blacklisted = blacklistStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        return blacklisted.contains(word.lowercased())
    }

    private func extractAppName(from context: String) -> String {
        return context.components(separatedBy: "]").first?.replacingOccurrences(of: "[", with: "") ?? ""
    }

    private func findProjectByFingerprint(for context: String) -> Project? {
        let descriptor = FetchDescriptor<Project>()
        guard let projects = try? modelContext.fetch(descriptor) else { return nil }
        let lowercaseContext = context.lowercased()
        
        var matches: [(project: Project, fingerprint: String)] = []
        for project in projects {
            for fingerprint in project.fingerprints {
                if lowercaseContext.contains(fingerprint.lowercased()) {
                    matches.append((project, fingerprint))
                }
            }
        }
        return matches.sorted { $0.fingerprint.count > $1.fingerprint.count }.first?.project
    }

    // --- OLD HELPERS ---

    private func isSimilar(_ old: String, _ new: String) -> Bool {
        let oldApp = old.components(separatedBy: "]").first ?? ""
        let newApp = new.components(separatedBy: "]").first ?? ""
        return oldApp == newApp && !oldApp.isEmpty
    }
    
    private func matchFirstGroup(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func getOrCreateProject(named name: String) -> Project {
        let cleanName = name.capitalized
        let descriptor = FetchDescriptor<Project>()
        if let projects = try? modelContext.fetch(descriptor),
           let existing = projects.first(where: { $0.name.lowercased() == cleanName.lowercased() }) {
            return existing
        }
        
        let colors = ["#B12425", "#F2BC2F", "#7B1315", "#E25926", "#4A90E2", "#50E3C2", "#F5A623", "#7ED321", "#9013FE", "#BD10E0", "#4A4A4A"]
        let newProject = Project(name: cleanName, colorHex: colors.randomElement() ?? "#B12425", fingerprints: [name.lowercased()])
        modelContext.insert(newProject)
        return newProject
    }
    
    private func active_entry_access() -> TimeEntry? {
        return activeEntry
    }
}

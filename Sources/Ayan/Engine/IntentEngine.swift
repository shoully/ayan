import Foundation
import SwiftData

@MainActor
class IntentEngine {
    private var modelContext: ModelContext
    private var activeEntry: TimeEntry?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Processes a new context string from the Watcher
    func process(context: String) -> Project? {
        // 1. Try to find a matching project
        var matchedProject = findProject(for: context)
        
        // 2. If no match, try to auto-detect from the context
        if matchedProject == nil {
            matchedProject = autoDetectProject(from: context)
        }
        
        // 3. Handle entry stability and state changes
        var newStartTime = Date()
        
        if let current = active_entry_access() {
            // If the project is the same (or both are Drift), check for similarity
            let projectsMatch = current.projectName == matchedProject?.name
            
            if projectsMatch || isSimilar(current.context, context) {
                // Combine: Just update context and keep the current entry running
                current.context = context
                // If it was drift but now we matched a project, upgrade it
                if current.isDrift && matchedProject != nil {
                    current.isDrift = false
                    current.projectName = matchedProject!.name
                    current.projectColorHex = matchedProject!.colorHex
                }
                return matchedProject
            }
            
            // State truly changed! Close the old entry
            current.end = Date()
            let duration = Int(Date().timeIntervalSince(current.start))
            
            // If the activity was less than 15 seconds, it's probably just passing through (Cmd+Tab)
            if duration < 15 {
                // Absorb this short time into the NEW entry we are about to create
                newStartTime = current.start
                modelContext.delete(current)
            } else {
                if duration > 0 {
                    print("💾 Saved: \(current.projectName ?? "Drift") (\(duration)s)")
                }
            }
        }
        
        // 4. Create a new entry for the new state
        let newEntry = TimeEntry(
            start: newStartTime,
            context: context,
            isDrift: matchedProject == nil,
            project: matchedProject
        )
        modelContext.insert(newEntry)
        activeEntry = newEntry
        
        let stateLabel = matchedProject?.name ?? "🌊 Drift"
        print("🧠 New State: \(stateLabel) | \"\(context)\"")
        
        // Trigger Nudge only for significant project switches
        if let project = matchedProject {
            NudgeWindowController.shared.show(
                projectName: project.name,
                colorHex: project.colorHex
            ) {
                print("✅ Confirmed: \(project.name)")
            }
        }
        
        return matchedProject
    }
    
    // Check if two context strings are similar enough to be combined
    private func isSimilar(_ old: String, _ new: String) -> Bool {
        // Extract app names [App]
        let oldApp = old.components(separatedBy: "]").first ?? ""
        let newApp = new.components(separatedBy: "]").first ?? ""
        
        guard oldApp == newApp && !oldApp.isEmpty else { return false }
        
        // If we are in the same app, combine them to keep the timeline clean
        // The process() method already ensures we split if a project is detected
        return true
    }
    
    // Auto-detect project from path patterns or URLs in the window title/context
    private func autoDetectProject(from context: String) -> Project? {
        // Read dynamic keywords from AppStorage
        let defaults = UserDefaults.standard
        
        let codeRootsStr = defaults.string(forKey: "customCodeRoots") ?? "apps, Sites, Code, Developer, projects, work, github, repositories, src, lab"
        let codeRoots = codeRootsStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        let serviceNamesStr = defaults.string(forKey: "customServiceNames") ?? "cPanel, Vercel, Netlify, Heroku, Supabase, Firebase, Linear, Slack, Discord, Appray"
        let serviceNames = serviceNamesStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        let blacklistStr = defaults.string(forKey: "customBlacklist") ?? "google, github, localhost, 127, apple, microsoft, amazon, facebook, twitter, linkedin, Home, Index, Login, Dashboard, Untitled, Google Search, Privacy Policy, Terms of Service, node, python, bash, zsh, docker, root, admin, main, master, develop, debug, release, documents, desktop, downloads, library, applications, users, pictures, movies, public, shared, bin, etc, var, tmp"
        let blacklisted = blacklistStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty }
        
        // 1. Try to find URLs or domains
        let urlPattern = "(?i)(?:https?://)?(?:www\\.)?([^/\\s:\\?#\\(\\)]+)"
        if let domain = matchFirstGroup(in: context, pattern: urlPattern) {
            let parts = domain.components(separatedBy: ".")
            if parts.count >= 2 {
                let brand = parts[max(0, parts.count - 2)].lowercased()
                if !blacklisted.contains(brand) && brand.count > 3 {
                    return getOrCreateProject(named: brand)
                }
            }
        }
        
        // 2. Look for common service/brand names or context keywords
        for service in serviceNames {
            if context.lowercased().contains(service.lowercased()) {
                return getOrCreateProject(named: service)
            }
        }
        
        // 3. Extract from title separators (e.g., "Page Title | ProjectName")
        let separators = [" | ", " - ", " — ", " : "]
        for sep in separators {
            let parts = context.components(separatedBy: sep)
            if parts.count > 1 {
                let lastPart = parts.last!.trimmingCharacters(in: .whitespacesAndNewlines)
                if lastPart.count > 3 && lastPart.count < 25 {
                    // Check if the last part looks like a project name
                    if !blacklisted.contains(lastPart.lowercased()) {
                        return getOrCreateProject(named: lastPart)
                    }
                }
            }
        }
        
        // 4. Try to find a code root followed by a project folder
        for root in codeRoots {
            let pathPattern = "(?i)(?:/|\(root)/|~\(root)/| \(root)/|\(root)/)([^/\\s:\\]]+)"
            if let name = matchFirstGroup(in: context, pattern: pathPattern) {
                if name.lowercased() != root.lowercased() && !blacklisted.contains(name.lowercased()) {
                    return getOrCreateProject(named: name)
                }
            }
            
            let bracketPattern = "(?i)\\[\(root)\\](?:\\[.*?\\])*\\[([^\\]]+)\\]"
            if let name = matchFirstGroup(in: context, pattern: bracketPattern) {
                if !blacklisted.contains(name.lowercased()) {
                    return getOrCreateProject(named: name)
                }
            }
        }
        
        // 5. Look for project names in parentheses (common in prompts)
        let parenPattern = "(?<![a-zA-Z0-9])\\(([^/\\s:\\]\\(\\)]{3,})\\)(?![a-zA-Z0-9])"
        if let name = matchFirstGroup(in: context, pattern: parenPattern) {
            if !blacklisted.contains(name.lowercased()) {
                return getOrCreateProject(named: name)
            }
        }
        
        // 6. Fallback: Last component of any absolute or home-relative path
        let fallbackPattern = "(?:/|~)(?:[^/\\s:\\]]+/)+([^/\\s:\\]]+)"
        if let name = matchFirstGroup(in: context, pattern: fallbackPattern) {
            if !blacklisted.contains(name.lowercased()) && name.count > 2 {
                return getOrCreateProject(named: name)
            }
        }
        
        return nil
    }
    
    private func matchFirstGroup(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return nil
        }
        let result = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        return result.isEmpty ? nil : result
    }
    
    private func getOrCreateProject(named name: String) -> Project {
        let descriptor = FetchDescriptor<Project>()
        if let projects = try? modelContext.fetch(descriptor),
           let existing = projects.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return existing
        }
        
        let colors = ["#B12425", "#F2BC2F", "#7B1315", "#E25926", "#4A90E2", "#50E3C2", "#F5A623", "#7ED321", "#9013FE", "#BD10E0", "#4A4A4A"]
        let randomColor = colors.randomElement() ?? "#B12425"
        
        let newProject = Project(
            name: name.capitalized,
            colorHex: randomColor,
            fingerprints: [name.lowercased()]
        )
        modelContext.insert(newProject)
        print("✨ Auto-discovered project: \(newProject.name)")
        return newProject
    }
    
    // Helper to safely access entry (fixes potential naming collision)
    private func active_entry_access() -> TimeEntry? {
        return activeEntry
    }
    
    private func findProject(for context: String) -> Project? {
        let descriptor = FetchDescriptor<Project>()
        guard let projects = try? modelContext.fetch(descriptor) else { return nil }
        
        let lowercaseContext = context.lowercased()
        
        // Find all matching fingerprints and their associated projects
        var matches: [(project: Project, fingerprint: String)] = []
        
        for project in projects {
            for fingerprint in project.fingerprints {
                if lowercaseContext.contains(fingerprint.lowercased()) {
                    matches.append((project, fingerprint))
                }
            }
        }
        
        // Return the project with the longest (most specific) matching fingerprint
        return matches.sorted { $0.fingerprint.count > $1.fingerprint.count }.first?.project
    }
}

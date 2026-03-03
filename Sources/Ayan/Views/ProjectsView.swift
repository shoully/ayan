import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) var projects: [Project]
    var entries: [TimeEntry]
    
    @State private var showingProjectSheet = false
    @State private var editingProject: Project?
    @State private var projectName = ""
    @State private var projectKeywords = ""
    
    var body: some View {
        let totalSeconds = entries.reduce(0) { $0 + $1.duration }
        
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .lastTextBaseline) {
                Text("Project Overview")
                    .font(.title2).bold()
                Spacer()
                Button { 
                    editingProject = nil
                    projectName = ""
                    projectKeywords = ""
                    showingProjectSheet = true 
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
            }
            .padding([.horizontal, .top])
            .padding(.bottom, 12)
            
            ScrollView {
                VStack(spacing: 12) {
                    // 1. Get all unique project names that have entries but aren't in the Project database
                    let entryProjectNames = Set(entries.compactMap { $0.projectName })
                    let databaseProjectNames = Set(projects.map { $0.name })
                    let orphanProjectNames = entryProjectNames.subtracting(databaseProjectNames)
                    
                    // 2. Combine Database Projects + Orphan Project Names (from entries)
                    // We want to show EVERYTHING.
                    
                    // Group entries for easy lookup
                    let groupedByProject = Dictionary(grouping: entries) { $0.projectName ?? "Uncategorized" }
                    
                    // Display Database Projects first
                    ForEach(projects) { project in
                        let projectEntries = groupedByProject[project.name] ?? []
                        let projectDuration = projectEntries.reduce(0) { $0 + $1.duration }
                        
                        ProjectSummaryCard(
                            projectName: project.name,
                            projectColor: Color(hex: project.colorHex) ?? .red,
                            entries: projectEntries,
                            totalProjectSeconds: projectDuration,
                            totalOverallSeconds: totalSeconds,
                            isUncategorized: false,
                            onEdit: {
                                editingProject = project
                                projectName = project.name
                                projectKeywords = project.fingerprints.joined(separator: ", ")
                                showingProjectSheet = true
                            }
                        )
                    }
                    
                    // Display Orphan Projects (detected but not "Created" as models yet)
                    ForEach(Array(orphanProjectNames).sorted(), id: \.self) { pName in
                        let projectEntries = groupedByProject[pName] ?? []
                        let projectDuration = projectEntries.reduce(0) { $0 + $1.duration }
                        let projectColorHex = projectEntries.first?.projectColorHex
                        
                        ProjectSummaryCard(
                            projectName: pName,
                            projectColor: Color(hex: projectColorHex ?? "") ?? .red,
                            entries: projectEntries,
                            totalProjectSeconds: projectDuration,
                            totalOverallSeconds: totalSeconds,
                            isUncategorized: false,
                            onEdit: {
                                // Create a new model from this orphan
                                editingProject = nil
                                projectName = pName
                                projectKeywords = pName.lowercased()
                                showingProjectSheet = true
                            }
                        )
                    }
                    
                    // Display Uncategorized
                    if let uncategorizedEntries = groupedByProject["Uncategorized"] {
                        let duration = uncategorizedEntries.reduce(0) { $0 + $1.duration }
                        ProjectSummaryCard(
                            projectName: "Uncategorized",
                            projectColor: .gray.opacity(0.5),
                            entries: uncategorizedEntries,
                            totalProjectSeconds: duration,
                            totalOverallSeconds: totalSeconds,
                            isUncategorized: true,
                            onEdit: {}
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .sheet(isPresented: $showingProjectSheet) {
            VStack(spacing: 20) {
                Text(editingProject == nil ? "New Project" : "Edit Project").font(.headline)
                TextField("Project Name", text: $projectName)
                    .textFieldStyle(.roundedBorder)
                TextField("Keywords (comma separated)", text: $projectKeywords)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    if let projectToDelete = editingProject {
                        Button("Delete", role: .destructive) {
                            deleteProject(projectToDelete)
                            showingProjectSheet = false
                        }
                    }
                    
                    Spacer()
                    
                    Button("Cancel") { showingProjectSheet = false }
                        .keyboardShortcut(.cancelAction)
                    
                    Button(editingProject == nil ? "Add" : "Save", action: saveProject)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
            .frame(width: 300)
        }
    }
    
    private func saveProject() {
        let keywords = projectKeywords.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        if let project = editingProject {
            let oldName = project.name
            let newName = projectName
            
            project.name = newName
            project.fingerprints = keywords
            
            if oldName != newName {
                let fetchDescriptor = FetchDescriptor<TimeEntry>(predicate: #Predicate { $0.projectName == oldName })
                if let entriesToUpdate = try? modelContext.fetch(fetchDescriptor) {
                    for entry in entriesToUpdate {
                        entry.projectName = newName
                    }
                }
            }
        } else {
            let newProject = Project(name: projectName, fingerprints: keywords)
            modelContext.insert(newProject)
        }
        
        try? modelContext.save()
        
        projectName = ""
        projectKeywords = ""
        showingProjectSheet = false
    }

    private func deleteProject(_ project: Project) {
        let nameToDelete = project.name
        
        let fetchDescriptor = FetchDescriptor<TimeEntry>(predicate: #Predicate { $0.projectName == nameToDelete })
        if let entriesToUpdate = try? modelContext.fetch(fetchDescriptor) {
            for entry in entriesToUpdate {
                entry.projectName = nil
                entry.projectColorHex = nil
            }
        }
        
        modelContext.delete(project)
        try? modelContext.save()
    }
}

struct ProjectSummaryCard: View {
    let projectName: String
    let projectColor: Color
    let entries: [TimeEntry]
    let totalProjectSeconds: Int
    let totalOverallSeconds: Int
    let isUncategorized: Bool
    let onEdit: () -> Void
    
    @State private var isExpanded = false
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                if !entries.isEmpty {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(projectColor)
                        .frame(width: 10, height: 10)
                        
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(projectName)
                                .font(.headline)
                                .foregroundStyle(isUncategorized ? .secondary : .primary)
                            
                            if !isUncategorized {
                                Button(action: onEdit) {
                                    Image(systemName: "pencil")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .opacity(isHovering ? 1 : 0)
                            }
                        }
                        
                        if entries.isEmpty {
                            Text("No activity yet. Add keywords to auto-detect.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        } else {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.1))
                                    
                                    Capsule()
                                        .fill(projectColor.opacity(0.8))
                                        .frame(width: max(0, geo.size.width * CGFloat(totalProjectSeconds) / CGFloat(max(1, totalOverallSeconds))))
                                }
                            }
                            .frame(height: 4)
                        }
                    }
                    
                    Spacer()
                    
                    if !entries.isEmpty {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatDuration(seconds: totalProjectSeconds))
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            
                            let percentage = Double(totalProjectSeconds) / Double(max(1, totalOverallSeconds))
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
                }
                .padding()
                .background(Color.primary.opacity(isExpanded ? 0.05 : 0.02))
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHovering = hovering
                    }
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded && !entries.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                    
                    // Group by App Name inside this project
                    let groupedByApp = Dictionary(grouping: entries) { $0.appName }
                    let sortedApps = groupedByApp.keys.sorted { a1, a2 in
                        let d1 = groupedByApp[a1]?.reduce(0) { $0 + $1.duration } ?? 0
                        let d2 = groupedByApp[a2]?.reduce(0) { $0 + $1.duration } ?? 0
                        return d1 > d2
                    }
                    
                    ForEach(sortedApps, id: \.self) { app in
                        let appEntries = groupedByApp[app] ?? []
                        let appDuration = appEntries.reduce(0) { $0 + $1.duration }
                        
                        HStack(alignment: .top, spacing: 10) {
                            Text(app)
                                .font(.callout.bold())
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .leading)
                                .lineLimit(1)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                // Show unique contexts for this app
                                let uniqueContexts = Array(Set(appEntries.map { $0.context.replacingOccurrences(of: "[\($0.appName)]", with: "").trimmingCharacters(in: .whitespaces) }))
                                    .filter { !$0.isEmpty && $0 != "Active" }
                                
                                if uniqueContexts.isEmpty {
                                    Text("Active")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                } else {
                                    ForEach(uniqueContexts.prefix(3), id: \.self) { ctx in
                                        Text("• \(ctx)")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                            .lineLimit(1)
                                    }
                                    if uniqueContexts.count > 3 {
                                        Text("  + \(uniqueContexts.count - 3) more...")
                                            .font(.system(size: 9))
                                            .foregroundStyle(.quaternary)
                                    }
                                }
                            }
                            
                            Spacer(minLength: 16)
                            
                            Text(formatDuration(seconds: appDuration))
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        
                        if app != sortedApps.last {
                            Divider().padding(.leading, 32)
                        }
                    }
                }
                .background(Color.primary.opacity(0.02))
            }
        }
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

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
            ScrollView {
                VStack(spacing: 0) {
                    let entryProjectNames = Set(entries.compactMap { $0.projectName })
                    let databaseProjectNames = Set(projects.map { $0.name })
                    let orphanProjectNames = entryProjectNames.subtracting(databaseProjectNames)
                    let groupedByProject = Dictionary(grouping: entries) { $0.projectName ?? "Uncategorized" }
                    
                    // Add New Project Row
                    Button {
                        editingProject = nil
                        projectName = ""
                        projectKeywords = ""
                        showingProjectSheet = true
                    } label: {
                        HStack {
                            Label("Create New Project", systemImage: "plus.circle.fill")
                                .font(.system(size: 13, weight: .medium))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                        .hoverEffect()
                    }
                    .buttonStyle(.plain)
                    
                    Divider().padding(.horizontal, 16).opacity(0.3)

                    // Database Projects
                    ForEach(projects) { project in
                        let projectEntries = groupedByProject[project.name] ?? []
                        let projectDuration = projectEntries.reduce(0) { $0 + $1.duration }
                        
                        ProjectSummaryRow(
                            projectName: project.name,
                            projectColor: Color(hex: project.colorHex) ?? .accentColor,
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
                        
                        Divider().padding(.leading, 44).opacity(0.3)
                    }
                    
                    // Orphan Projects
                    ForEach(Array(orphanProjectNames).sorted(), id: \.self) { pName in
                        let projectEntries = groupedByProject[pName] ?? []
                        let projectDuration = projectEntries.reduce(0) { $0 + $1.duration }
                        let projectColorHex = projectEntries.first?.projectColorHex
                        
                        ProjectSummaryRow(
                            projectName: pName,
                            projectColor: Color(hex: projectColorHex ?? "") ?? .secondary,
                            entries: projectEntries,
                            totalProjectSeconds: projectDuration,
                            totalOverallSeconds: totalSeconds,
                            isUncategorized: false,
                            onEdit: {
                                editingProject = nil
                                projectName = pName
                                projectKeywords = pName.lowercased()
                                showingProjectSheet = true
                            }
                        )
                        
                        Divider().padding(.leading, 44).opacity(0.3)
                    }
                    
                    // Uncategorized
                    if let uncategorizedEntries = groupedByProject["Uncategorized"] {
                        let duration = uncategorizedEntries.reduce(0) { $0 + $1.duration }
                        ProjectSummaryRow(
                            projectName: "Uncategorized",
                            projectColor: .gray.opacity(0.3),
                            entries: uncategorizedEntries,
                            totalProjectSeconds: duration,
                            totalOverallSeconds: totalSeconds,
                            isUncategorized: true,
                            onEdit: {}
                        )
                    }
                }
                .padding(.vertical, 8)
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
                    for entry in entriesToUpdate { entry.projectName = newName }
                }
            }
        } else {
            let newProject = Project(name: projectName, fingerprints: keywords)
            modelContext.insert(newProject)
        }
        try? modelContext.save()
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

struct ProjectSummaryRow: View {
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
                    withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
                }
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(projectColor)
                        .frame(width: 8, height: 8)
                        
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(projectName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(isUncategorized ? .secondary : .primary)
                            
                            if !isUncategorized {
                                Button(action: onEdit) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .opacity(isHovering ? 1 : 0)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if !entries.isEmpty {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatDuration(seconds: totalProjectSeconds))
                                .font(.system(size: 11, weight: .bold))
                            let percentage = Double(totalProjectSeconds) / Double(max(1, totalOverallSeconds))
                            Text(String(format: "%.1f%%", percentage * 100))
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) { isHovering = hovering }
                }
                .hoverEffect()
            }
            .buttonStyle(.plain)
            
            if isExpanded && !entries.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
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
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .leading)
                                .lineLimit(1)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                let uniqueContexts = Array(Set(appEntries.map { $0.context.replacingOccurrences(of: "[\($0.appName)]", with: "").trimmingCharacters(in: .whitespaces) }))
                                    .filter { !$0.isEmpty && $0 != "Active" }
                                
                                if uniqueContexts.isEmpty {
                                    Text("Active")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                } else {
                                    ForEach(uniqueContexts.prefix(3), id: \.self) { ctx in
                                        Text("• \(ctx)")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.tertiary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Text(formatDuration(seconds: appDuration))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 44)
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
    if hours > 0 { return "\(hours)h \(minutes)m" }
    else if minutes > 0 { return "\(minutes)m" }
    else { return "\(seconds)s" }
}

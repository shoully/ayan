import SwiftUI
import SwiftData

struct ProjectsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.name) var projects: [Project]
    
    @State private var showingProjectSheet = false
    @State private var editingProject: Project?
    @State private var projectName = ""
    @State private var projectKeywords = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Managed Projects")
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
            .padding([.top, .horizontal])

            List {
                ForEach(projects) { project in
                    HStack {
                        Circle()
                            .fill(project.color)
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading) {
                            Text(project.name)
                                .fontWeight(.semibold)
                            Text(project.fingerprints.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingProject = project
                        projectName = project.name
                        projectKeywords = project.fingerprints.joined(separator: ", ")
                        showingProjectSheet = true
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            deleteProject(project)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
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
    }
}

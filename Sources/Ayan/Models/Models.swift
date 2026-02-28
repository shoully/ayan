import Foundation
import SwiftData

@Model
final class Project {
    var name: String
    var colorHex: String
    var fingerprints: [String] // Keywords to match in window titles/URLs
    
    init(name: String, colorHex: String = "#B12425", fingerprints: [String] = []) {
        self.name = name
        self.colorHex = colorHex
        self.fingerprints = fingerprints
    }
}

@Model
final class TimeEntry {
    var start: Date
    var end: Date?
    var context: String // The raw window title captured
    var isDrift: Bool
    var activityType: String? // e.g., Coding, Communication, Research
    
    // Denormalized from Project to prevent deletion crashes
    var projectName: String?
    var projectColorHex: String?
    
    init(start: Date = Date(), context: String, isDrift: Bool = false, project: Project? = nil, activityType: String? = nil) {
        self.start = start
        self.context = context
        self.isDrift = isDrift
        self.projectName = project?.name
        self.projectColorHex = project?.colorHex
        self.activityType = activityType
    }
}

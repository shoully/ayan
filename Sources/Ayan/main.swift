import Cocoa
import SwiftUI
import SwiftData

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var ayanApp: AyanApp?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            ayanApp = try AyanApp()
            ayanApp?.start()
            print("🚀 Ayan is running in the background.")
            
            // Hide dock icon since we are a menu bar app
            NSApp.setActivationPolicy(.accessory)
        } catch {
            print("❌ Failed to start Ayan: \(error)")
        }
    }
}

@MainActor
class AyanApp {
    let container: ModelContainer
    let engine: IntentEngine
    let watcher: Watcher
    let menuBar: MenuBarController
    
    init() throws {
        self.container = try ModelContainer(for: Project.self, TimeEntry.self)
        self.engine = IntentEngine(modelContext: container.mainContext)
        self.watcher = Watcher()
        self.menuBar = MenuBarController(container: container)
        bootstrap()
    }
    
    func start() {
        performRetentionCleanup()
        watcher.onContextChange = { [weak self] context in
            let matchedProject = self?.engine.process(context: context)
            self?.menuBar.updateStatus(
                isFlow: matchedProject != nil,
                colorHex: matchedProject?.colorHex
            )
        }
        watcher.start()
    }
    
    private func performRetentionCleanup() {
        let days = UserDefaults.standard.integer(forKey: "retentionDays")
        guard days > 0 else { return }
        
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let context = container.mainContext
        
        do {
            try context.delete(model: TimeEntry.self, where: #Predicate<TimeEntry> { $0.start < cutoff })
            try context.save()
            print("🧹 Data Retention: Cleaned up entries older than \(days) days.")
        } catch {
            print("❌ Cleanup failed: \(error)")
        }
    }
    
    private func bootstrap() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<Project>()
        // No hardcoded projects needed; the IntentEngine will auto-discover them
        if let projects = try? context.fetch(descriptor), projects.isEmpty {
            print("🆕 Ayan initialized. Projects will be auto-detected from window titles.")
        }
    }
}

// Global Watcher (same as before)
@MainActor
class Watcher {
    var onContextChange: (@MainActor (String) -> Void)?
    private let workspace = NSWorkspace.shared
    private var lastContext: String = ""

    func start() {
        checkPermissions()
        workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkCurrentContext()
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkCurrentContext()
            }
        }
    }

    private func checkPermissions() {
        // Check without prompting first
        let options = ["AXTrustedCheckOptionPrompt": false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            // Only prompt if we really don't have it
            print("⚠️ Accessibility permissions are missing! Window titles cannot be read.")
            let promptOptions = ["AXTrustedCheckOptionPrompt": true]
            AXIsProcessTrustedWithOptions(promptOptions as CFDictionary)
        }
    }

    private func checkCurrentContext() {
        guard let frontApp = workspace.frontmostApplication else { return }
        let appName = frontApp.localizedName ?? "Unknown"
        
        // Skip system/noise apps (Removed Finder from here to allow tracking)
        let systemApps = ["System Settings", "universalAccessAuthWarn", "UserNotificationCenter", "Dock", "loginwindow"]
        if systemApps.contains(appName) { return }
        
        var windowTitle = fetchAXWindowTitle(for: frontApp.processIdentifier)
        let deepContext = fetchDeepContext(for: frontApp)
        
        // If it's just the app name and no title/deep context, we still want to know the app is active
        // but we'll label it "Active" to avoid empty brackets
        if windowTitle.isEmpty && deepContext.isEmpty {
            windowTitle = "Active"
        }
        
        // Clean up title noise
        if windowTitle == "(No Window)" || windowTitle == "(Untitled)" {
            windowTitle = "Active"
        }
        
        let context = "[\(appName)] \(windowTitle) \(deepContext)".replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
        
        if context != lastContext && !context.isEmpty {
            print("🔍 Context changed: \(context)")
            lastContext = context
            onContextChange?(context)
        }
    }

    private func fetchAXWindowTitle(for pid: pid_t) -> String {
        let appRef = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        // Try to get the focused window
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &value)
        
        if result != .success {
            // Fallback: Try to get the main window if focused window fails
            AXUIElementCopyAttributeValue(appRef, kAXMainWindowAttribute as CFString, &value)
        }
        
        guard let windowRef = value as! AXUIElement? else { return "" }
        var titleValue: CFTypeRef?
        let titleResult = AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute as CFString, &titleValue)
        return (titleResult == .success ? (titleValue as? String) : nil) ?? ""
    }

    private func fetchDeepContext(for app: NSRunningApplication) -> String {
        let bundleId = app.bundleIdentifier ?? ""
        var script = ""
        
        switch bundleId {
        case "com.googlecode.iterm2":
            // Try to get specific path first, which is more descriptive, but fallback to the window name.
            script = """
            try
                tell application "iTerm2" to tell current session of current window to get value of variable "path"
            on error
                tell application "iTerm2" to get name of front window
            end try
            """
        case "com.apple.finder":
            script = "tell application \"Finder\" to get POSIX path of (target of front window as alias)"
        case "com.google.Chrome":
            script = "tell application \"Google Chrome\" to get URL of active tab of front window"
        case "com.apple.Safari":
            script = "tell application \"Safari\" to get URL of front document"
        case "org.mozilla.firefox":
            script = "tell application \"Firefox\" to get name of front window"
        case "com.apple.mail":
            script = "tell application \"Mail\" to get name of front window"
        case "com.apple.iWork.Pages":
            script = "tell application \"Pages\" to get name of front document"
        case "com.sublimetext.4", "com.sublimetext.3":
            script = "tell application \"Sublime Text\" to get name of front window"
        case "com.apple.dt.Xcode":
            script = "tell application \"Xcode\" to get name of front window"
        case "com.apple.iWork.Numbers":
            script = "tell application \"Numbers\" to get name of front document"
        case "com.apple.Stickies":
            script = "tell application \"Stickies\" to get name of front window"
        case "net.whatsapp.WhatsApp":
            script = "tell application \"WhatsApp\" to get name of front window"
        default:
            return ""
        }

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            if error == nil, let output = result.stringValue {
                return output
            }
        }
        return ""
    }
}

// Entry Point
let delegate = AppDelegate()
let app = NSApplication.shared
app.delegate = delegate
app.run()

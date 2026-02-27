import AppKit
import SwiftUI
import SwiftData

@MainActor
class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popoverManager: PopoverManager!
    private let container: ModelContainer
    private let popoverState = PopoverState()

    init(container: ModelContainer) {
        self.container = container
        super.init()
        
        // Setup Status Item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Ayan")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Setup the new PopoverManager and pass the shared state
        popoverManager = PopoverManager(statusItem: statusItem, container: container, state: popoverState)
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        popoverManager.toggle()
    }
    
    func updateStatus(isFlow: Bool, colorHex: String?) {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: isFlow ? "timer.circle.fill" : "timer", accessibilityDescription: "Ayan")
            
            // Tint the icon with the project color
            if isFlow, let colorHex = colorHex, let projectColor = Color(hex: colorHex) {
                button.contentTintColor = NSColor(projectColor)
            } else {
                button.contentTintColor = nil // Use default monochrome
            }
        }
    }
}

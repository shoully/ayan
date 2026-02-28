import AppKit
import SwiftUI

class NudgeWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class NudgeWindowController: NSWindowController {
    static let shared = NudgeWindowController()
    
    convenience init() {
        let window = NudgeWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 40),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.ignoresMouseEvents = false
        window.appearance = NSAppearance(named: .darkAqua)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        self.init(window: window)
    }
    
    func show(projectName: String, colorHex: String, onConfirm: @escaping () -> Void) {
        let view = NudgeView(
            projectName: projectName,
            color: Color(hex: colorHex) ?? .red,
            onConfirm: {
                onConfirm()
                self.hide()
            },
            onDismiss: { self.hide() }
        )
        
        window?.contentView = NSHostingView(rootView: view)
        
        // Position at the top center of the screen
        if let screen = NSScreen.main {
            let x = (screen.visibleFrame.width - 300) / 2
            let y = screen.visibleFrame.height - 60
            window?.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        window?.makeKeyAndOrderFront(nil)
        
        // Auto-hide after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            self.hide()
        }
    }
    
    func hide() {
        window?.orderOut(nil)
    }
}

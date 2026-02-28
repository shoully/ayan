import AppKit
import SwiftUI
import SwiftData

// Define a custom notification name for safely closing the popover
extension Notification.Name {
    static let popoverShouldClose = Notification.Name("ayan.popoverShouldClose")
}

@MainActor
class PopoverWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
class PopoverManager {
    private var window: PopoverWindow!
    private let statusItem: NSStatusItem
    private let state: PopoverState
    
    // These properties hold tokens from non-Sendable AppKit APIs.
    // They are marked as nonisolated to be safely cleaned up in deinit.
    nonisolated(unsafe) private var outsideClickMonitor: Any?
    nonisolated(unsafe) private var appFocusMonitor: Any?
    nonisolated(unsafe) private var popoverCloseObserver: Any?

    init(statusItem: NSStatusItem, container: ModelContainer, state: PopoverState) {
        self.statusItem = statusItem
        self.state = state
        setupWindow(container: container)
        setupMonitors()
    }
    
    deinit {
        // Now safe to call from nonisolated deinit
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = appFocusMonitor {
            NotificationCenter.default.removeObserver(monitor)
        }
        if let observer = popoverCloseObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupWindow(container: ModelContainer) {
        let view = NarrativeView(state: state).modelContainer(container)
        let hostingController = NSHostingController(rootView: view)
        let windowSize = NSSize(width: 380, height: 550 + 12)

        window = PopoverWindow(
            contentRect: NSRect(origin: .zero, size: windowSize),
            styleMask: [.borderless],
            backing: .buffered, defer: false
        )
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.appearance = NSAppearance(named: .darkAqua)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
    }
    
    private func setupMonitors() {
        // This monitor runs in the background. It posts a notification to be handled safely on the main thread.
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            NotificationCenter.default.post(name: .popoverShouldClose, object: nil)
        }
        
        // These observers use the safe selector pattern, which calls @objc methods on the main actor instance.
        popoverCloseObserver = NotificationCenter.default.addObserver(self, selector: #selector(handlePopoverShouldClose), name: .popoverShouldClose, object: nil)
        appFocusMonitor = NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillResignActive), name: NSApplication.willResignActiveNotification, object: nil)
    }
    
    @objc private func handlePopoverShouldClose() {
        guard window.isVisible, !state.isPinned else { return }
        hide()
    }
    
    @objc private func handleAppWillResignActive() {
        guard !state.isPinned else { return }
        hide()
    }

    func toggle() {
        if window.isVisible {
            hide()
        } else {
            show()
        }
    }

    private func show() {
        guard let button = statusItem.button, let screen = button.window?.screen else { return }

        let windowSize = window.frame.size
        let screenFrame = screen.visibleFrame
        let buttonFrame = button.window!.convertToScreen(button.frame)

        var x = buttonFrame.origin.x - (windowSize.width / 2) + (buttonFrame.width / 2)
        let y = buttonFrame.origin.y - windowSize.height - 3

        if x + windowSize.width > screenFrame.maxX {
            x = screenFrame.maxX - windowSize.width - 4
        }
        if x < screenFrame.minX {
            x = screenFrame.minX + 4
        }
        
        window.setFrameOrigin(NSPoint(x: x, y: y))
        
        window.alphaValue = 0
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window.animator().alphaValue = 1
        })
    }

    private func hide() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            window.animator().alphaValue = 0
        }, completionHandler: {
            // Ensure the final UI operation happens on the main thread
            DispatchQueue.main.async {
                self.window.orderOut(nil)
            }
        })
    }
}

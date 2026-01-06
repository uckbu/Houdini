import SwiftUI
import Cocoa
import Carbon

@main
struct HoudiniApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.cursorManager)
        }
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Quit Houdini") {
                    appDelegate.cursorManager.showCursor()
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate!
    
    let cursorManager = CursorManager()
    private var statusItem: NSStatusItem?
    
    // Default hotkey: Command + Option + H
    private var currentKeyCode: UInt32 = 0x04
    private var currentModifiers: UInt32 = UInt32(cmdKey | optionKey)
    
    override init() {
        super.init()
        AppDelegate.shared = self
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup menu bar icon so app persists when window is closed
        setupMenuBar()
        
        // Register global hotkey immediately
        registerHotkey()
        
        // Request accessibility permissions
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        if !accessEnabled {
            print("Accessibility access required for global cursor hiding.")
        }
        
        // Activate and show window
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "cursorarrow", accessibilityDescription: "Houdini")
        }
        
        let menu = NSMenu()
        
        let toggleItem = NSMenuItem(title: "Toggle Cursor (⌘⌥H)", action: #selector(toggleCursor), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let showWindowItem = NSMenuItem(title: "Show Window", action: #selector(showWindow), keyEquivalent: "")
        showWindowItem.target = self
        menu.addItem(showWindowItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    func registerHotkey() {
        HotKeyManager.shared.register(keyCode: currentKeyCode, modifiers: currentModifiers)
        HotKeyManager.shared.onHotKeyTriggered = { [weak self] in
            DispatchQueue.main.async {
                self?.cursorManager.toggleCursor()
                self?.updateMenuBarIcon()
            }
        }
    }
    
    func updateHotkey(keyCode: UInt32, modifiers: UInt32) {
        currentKeyCode = keyCode
        currentModifiers = modifiers
        registerHotkey()
    }
    
    private func updateMenuBarIcon() {
        if let button = statusItem?.button {
            let symbolName = cursorManager.isHidden ? "cursorarrow.slash" : "cursorarrow"
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Houdini")
        }
    }
    
    @objc private func toggleCursor() {
        cursorManager.toggleCursor()
        updateMenuBarIcon()
    }
    
    @objc private func showWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func quitApp() {
        cursorManager.showCursor()
        NSApplication.shared.terminate(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running in background when window is closed
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showWindow()
        }
        return true
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        cursorManager.showCursor()
    }
}

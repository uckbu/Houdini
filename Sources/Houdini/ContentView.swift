import SwiftUI
import Carbon

struct ContentView: View {
    @EnvironmentObject var cursorManager: CursorManager
    @State private var isRecording = false
    @State private var hotKeyLabel = "⌘ ⌥ H"
    
    // Default: Command + Option + H (kVK_ANSI_H is 0x04)
    @State private var currentKeyCode: UInt32 = 0x04
    @State private var currentModifiers: UInt32 = UInt32(cmdKey | optionKey)
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Houdini")
                .font(.system(size: 28, weight: .bold))
            
            // Status indicator
            HStack(spacing: 12) {
                Circle()
                    .fill(cursorManager.isHidden ? Color.red : Color.green)
                    .frame(width: 12, height: 12)
                Text(cursorManager.isHidden ? "Cursor is HIDDEN" : "Cursor is VISIBLE")
                    .font(.headline)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Divider()
            
            // Hotkey section
            VStack(spacing: 12) {
                Text("Global Hotkey")
                    .font(.headline)
                
                Button(action: {
                    isRecording = true
                }) {
                    HStack {
                        Image(systemName: "keyboard")
                        Text(isRecording ? "Press keys..." : hotKeyLabel)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                    }
                    .frame(minWidth: 180)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(isRecording ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isRecording ? Color.blue : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                if isRecording {
                    Text("Press a key combination...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Manual toggle button
            Button(action: {
                cursorManager.toggleCursor()
            }) {
                HStack {
                    Image(systemName: cursorManager.isHidden ? "eye" : "eye.slash")
                    Text(cursorManager.isHidden ? "Show Cursor" : "Hide Cursor")
                }
                .frame(minWidth: 140)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("App runs in background when window is closed.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Look for the cursor icon in the menu bar.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
        .padding(30)
        .frame(width: 400, height: 420)
        .background(KeyEventHandler(isRecording: $isRecording, keyCode: $currentKeyCode, modifiers: $currentModifiers, label: $hotKeyLabel))
        .onChange(of: currentKeyCode) { _ in updateHotkeyInAppDelegate() }
        .onChange(of: currentModifiers) { _ in updateHotkeyInAppDelegate() }
    }
    
    func updateHotkeyInAppDelegate() {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.updateHotkey(keyCode: currentKeyCode, modifiers: currentModifiers)
        }
    }
}

struct KeyEventHandler: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32
    @Binding var label: String
    
    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.parent = self
        return view
    }
    
    func updateNSView(_ nsView: KeyCaptureView, context: Context) {
        nsView.parent = self
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
}

class KeyCaptureView: NSView {
    var parent: KeyEventHandler?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        guard let parent = parent, parent.isRecording else {
            super.keyDown(with: event)
            return
        }
        
        // Need at least one modifier for a hotkey
        let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
        guard !mods.isEmpty else { return }
        
        // Convert NSEvent modifiers to Carbon modifiers
        var carbonModifiers: UInt32 = 0
        if event.modifierFlags.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        if event.modifierFlags.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if event.modifierFlags.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        if event.modifierFlags.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        
        parent.keyCode = UInt32(event.keyCode)
        parent.modifiers = carbonModifiers
        
        // Generate pretty label with symbols
        var keys: [String] = []
        if event.modifierFlags.contains(.control) { keys.append("⌃") }
        if event.modifierFlags.contains(.option) { keys.append("⌥") }
        if event.modifierFlags.contains(.shift) { keys.append("⇧") }
        if event.modifierFlags.contains(.command) { keys.append("⌘") }
        
        if let chars = event.charactersIgnoringModifiers?.uppercased(), !chars.isEmpty {
            keys.append(chars)
        }
        
        parent.label = keys.joined(separator: " ")
        parent.isRecording = false
    }
}


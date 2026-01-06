import Carbon
import Cocoa

class HotKeyManager {
    static let shared = HotKeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var currentHotKeyID: UInt32 = 1
    
    var onHotKeyTriggered: (() -> Void)?
    
    private init() {
        installEventHandler()
    }
    
    private func installEventHandler() {
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        // Install event handler
        let handler: EventHandlerUPP = { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if status == noErr && hotKeyID.id == manager.currentHotKeyID {
                manager.onHotKeyTriggered?()
                return noErr
            }
            
            return OSStatus(eventNotHandledErr)
        }
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            selfPointer,
            &eventHandler
        )
        
        if status != noErr {
            print("Failed to install event handler: \(status)")
        }
    }
    
    func register(keyCode: UInt32, modifiers: UInt32) {
        // Unregister previous hotkey
        if let hotKeyRef = hotKeyRef {
            let status = UnregisterEventHotKey(hotKeyRef)
            if status != noErr {
                 print("Failed to unregister hotkey: \(status)")
            }
            self.hotKeyRef = nil
        }
        
        currentHotKeyID += 1
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = fourCharCode("CHDR")
        hotKeyID.id = currentHotKeyID
        
        // Register new hotkey
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status != noErr {
            print("Failed to register hotkey: \(status)")
        } else {
            print("Hotkey registered (keyCode: \(keyCode), modifiers: \(modifiers), id: \(currentHotKeyID))")
        }
    }
    
    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        // Handler removal is moved to deinit or typically not needed for singleton
    }
    
    deinit {
        unregister()
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}

private func fourCharCode(_ string: String) -> OSType {
    var result: OSType = 0
    for char in string.utf8.prefix(4) {
        result = (result << 8) + OSType(char)
    }
    return result
}

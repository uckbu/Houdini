import Cocoa
import CoreGraphics

// Private CoreGraphics Server (CGS) API declarations
// These allow setting cursor properties even when app is in background
@_silgen_name("CGSSetConnectionProperty")
func CGSSetConnectionProperty(_ connection: Int32, _ targetConnection: Int32, _ key: CFString, _ value: CFBoolean) -> Int32

@_silgen_name("_CGSDefaultConnection")
func _CGSDefaultConnection() -> Int32

final class CursorManager: ObservableObject {
    @Published private(set) var isHidden = false
    
    // Timer for continuous hiding
    private var hideTimer: DispatchSourceTimer?
    private let timerQueue = DispatchQueue(label: "com.cursorhider.timer", qos: .userInteractive)
    
    // Event monitors
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    // Track hide calls for proper balancing
    private var hideCount: Int = 0
    private let lock = NSLock()
    
    init() {
        // CRITICAL: Enable background cursor setting via private API
        // This is what makes Cursorcerer and similar apps work
        enableBackgroundCursorSetting()
    }
    
    private func enableBackgroundCursorSetting() {
        let key = "SetsCursorInBackground" as CFString
        let connection = _CGSDefaultConnection()
        let result = CGSSetConnectionProperty(connection, connection, key, kCFBooleanTrue)
        if result == 0 {
            print("Successfully enabled SetsCursorInBackground")
        } else {
            print("Failed to enable SetsCursorInBackground: \(result)")
        }
    }
    
    func toggleCursor() {
        if isHidden {
            showCursor()
        } else {
            hideCursor()
        }
    }
    
    func hideCursor() {
        guard !isHidden else { return }
        
        // Reset hide count
        lock.lock()
        hideCount = 0
        lock.unlock()
        
        // Hide the cursor immediately
        CGDisplayHideCursor(CGMainDisplayID())
        incrementHideCount()
        
        // Setup continuous hiding timer
        startHideTimer()
        
        // Setup event monitors to re-hide on any mouse activity
        setupEventMonitors()
        
        DispatchQueue.main.async {
            self.isHidden = true
        }
    }
    
    private func incrementHideCount() {
        lock.lock()
        hideCount += 1
        lock.unlock()
    }
    
    private func startHideTimer() {
        hideTimer?.cancel()
        
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: timerQueue)
        // 16ms interval (~60Hz) - sufficient with the background API enabled
        timer.schedule(deadline: .now(), repeating: .milliseconds(16), leeway: .milliseconds(1))
        
        timer.setEventHandler { [weak self] in
            guard let self = self, self.isHidden else { return }
            CGDisplayHideCursor(CGMainDisplayID())
            self.incrementHideCount()
        }
        
        hideTimer = timer
        timer.resume()
    }
    
    private func setupEventMonitors() {
        removeEventMonitors()
        
        // Global monitor for events when app is in background
        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged, .scrollWheel]
        ) { [weak self] _ in
            guard let self = self, self.isHidden else { return }
            CGDisplayHideCursor(CGMainDisplayID())
            self.incrementHideCount()
        }
        
        // Local monitor for events when app is active
        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged, .scrollWheel]
        ) { [weak self] event in
            guard let self = self, self.isHidden else { return event }
            CGDisplayHideCursor(CGMainDisplayID())
            self.incrementHideCount()
            return event
        }
    }
    
    private func removeEventMonitors() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    func showCursor() {
        guard isHidden else { return }
        
        // Mark as not hidden FIRST to stop timer/monitor callbacks
        DispatchQueue.main.async {
            self.isHidden = false
        }
        
        // Stop all hiding mechanisms
        hideTimer?.cancel()
        hideTimer = nil
        removeEventMonitors()
        
        // Small delay to ensure timer/monitors have stopped
        Thread.sleep(forTimeInterval: 0.05)
        
        // Get final hide count
        lock.lock()
        let count = hideCount
        hideCount = 0
        lock.unlock()
        
        // Show cursor once for each hide call, plus extra to be safe
        let showCount = count + 50
        for _ in 0..<showCount {
            CGDisplayShowCursor(CGMainDisplayID())
        }
        
        print("Showed cursor \(showCount) times (hide count was \(count))")
    }
    
    deinit {
        hideTimer?.cancel()
        removeEventMonitors()
        
        // Ensure cursor is visible - show many times
        for _ in 0..<1000 {
            CGDisplayShowCursor(CGMainDisplayID())
        }
    }
}

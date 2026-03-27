import ApplicationServices
import Cocoa

class ClipboardService {
    static let shared = ClipboardService()

    // Dependency injection for license checking
    private var licenseManager: LicenseManager {
        return LicenseManager.shared
    }

    private init() {}

    func copy(text: String) {
        let finalText = wrapTextIfNeeded(text)
    
        // Type each character directly without touching the clipboard
        DispatchQueue.main.async {
            let source = CGEventSource(stateID: .hidSystemState)
            for scalar in finalText.unicodeScalars {
                let char = UniChar(scalar.value)
                var charArray = [char]
                let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
                keyDown?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &charArray)
                let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
                keyUp?.keyboardSetUnicodeString(stringLength: 1, unicodeString: &charArray)
                keyDown?.post(tap: .cghidEventTap)
                keyUp?.post(tap: .cghidEventTap)
            }
            print("✅ Typed directly: '\(finalText.prefix(20))...'")
        }
    }

    // Paste content (Simulate Cmd+V)
    func paste() {
        // Create a concurrent task to avoid blocking main thread if needed,
        // though CGEvent is fast.
        DispatchQueue.main.async {
            let source = CGEventSource(stateID: .hidSystemState)

            // Command key down
            let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
            cmdDown?.flags = .maskCommand

            // 'V' key down
            let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            vDown?.flags = .maskCommand

            // 'V' key up
            let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            vUp?.flags = .maskCommand

            // Command key up
            let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

            // Post events
            cmdDown?.post(tap: .cghidEventTap)
            vDown?.post(tap: .cghidEventTap)
            vUp?.post(tap: .cghidEventTap)
            cmdUp?.post(tap: .cghidEventTap)

            print("Simulated Cmd+V")
        }
    }

    // Fallback using AppleScript (more robust for some apps)
    func appleScriptPaste() {
        let script = "tell application \"System Events\" to keystroke \"v\" using command down"
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript Paste Error: \(error)")
            } else {
                print("Executed AppleScript Paste")
            }
        }
    }

    // Check if we have permission to send keystrokes
    var isAccessibilityTrusted: Bool {
        return AXIsProcessTrusted()
    }

    // Request permission via system prompt
    func requestAccessibilityPermission() {
        let options =
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}

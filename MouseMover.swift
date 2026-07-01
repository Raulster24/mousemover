import Cocoa
import IOKit.pwr_mgt
import CoreGraphics
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var timer: Timer?
    var assertionID: IOPMAssertionID = 0
    var active = false
    var interval: TimeInterval = 60
    let choices = [15, 30, 60, 120, 300]
    var busy = false

    func applicationDidFinishLaunching(_ note: Notification) {
        buildMenu()
        start()   // active by default
    }

    // MARK: - Menu

    func buildMenu() {
        let menu = NSMenu()

        let toggle = NSMenuItem(title: active ? "Stop" : "Start",
                                action: #selector(toggleActive), keyEquivalent: "s")
        toggle.target = self
        menu.addItem(toggle)

        let move = NSMenuItem(title: "Move now (test)", action: #selector(moveNow), keyEquivalent: "m")
        move.target = self
        menu.addItem(move)

        let status = NSMenuItem(title: active ? "Status: ● Active" : "Status: ○ Paused",
                                action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)

        menu.addItem(NSMenuItem.separator())

        let intItem = NSMenuItem(title: "Move every", action: nil, keyEquivalent: "")
        let intMenu = NSMenu()
        for s in choices {
            let mi = NSMenuItem(title: "\(s) seconds",
                                action: #selector(setInterval(_:)), keyEquivalent: "")
            mi.target = self
            mi.tag = s
            mi.state = (Int(interval) == s) ? .on : .off
            intMenu.addItem(mi)
        }
        intItem.submenu = intMenu
        menu.addItem(intItem)

        if !AXIsProcessTrusted() {
            menu.addItem(NSMenuItem.separator())
            let warn = NSMenuItem(title: "⚠ Enable Accessibility (for Teams/Slack idle)…",
                                  action: #selector(openAccessibility), keyEquivalent: "")
            warn.target = self
            menu.addItem(warn)
        }

        menu.addItem(NSMenuItem.separator())
        let quit = NSMenuItem(title: "Quit MouseMover", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        updateIcon()
    }

    func updateIcon() {
        guard let btn = statusItem.button else { return }
        let name = active ? "cup.and.saucer.fill" : "cup.and.saucer"
        if let img = NSImage(systemSymbolName: name, accessibilityDescription: "MouseMover") {
            img.isTemplate = true
            btn.image = img
        } else {
            btn.title = active ? "☕︎" : "○"
        }
    }

    // MARK: - Actions

    @objc func toggleActive() { active ? stop() : start() }
    @objc func moveNow() { drawCircle() }

    @objc func setInterval(_ sender: NSMenuItem) {
        interval = TimeInterval(sender.tag)
        if active { restartTimer() }
        buildMenu()
    }

    @objc func openAccessibility() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    @objc func quit() { stop(); NSApp.terminate(nil) }

    // MARK: - Core

    func start() {
        active = true
        // Optional: ask for Accessibility so the movement also counts as
        // real input for idle-tracking apps (Teams, Slack). The visible
        // movement itself works WITHOUT this permission.
        let opts: CFDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
        IOPMAssertionCreateWithName(kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                                    IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                    "MouseMover keeping display awake" as CFString,
                                    &assertionID)
        restartTimer()
        drawCircle()          // move immediately so you can see it working
        buildMenu()
    }

    func stop() {
        active = false
        timer?.invalidate(); timer = nil
        if assertionID != 0 { IOPMAssertionRelease(assertionID); assertionID = 0 }
        buildMenu()
    }

    func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.drawCircle()
        }
    }

    /// Move the cursor in a quick, visible circle, then return it to where it was.
    func drawCircle() {
        if busy { return }
        busy = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            defer { self?.busy = false }
            let start = CGEvent(source: nil)?.location ?? CGPoint(x: 500, y: 500)
            let radius: CGFloat = 70
            let steps = 72
            for i in 0...steps {
                let a = (Double(i) / Double(steps)) * 2.0 * Double.pi
                let p = CGPoint(x: start.x + CGFloat(cos(a)) * radius,
                                y: start.y + CGFloat(sin(a)) * radius)
                self?.move(p)
                usleep(7000)   // ~0.5s for a full circle
            }
            self?.move(start)  // put the cursor back
            // Re-sync the physical mouse after warping.
            CGAssociateMouseAndMouseCursorPosition(1)
        }
    }

    /// Warp (works with no permission) + post a move event (resets idle timers
    /// when Accessibility is granted). Belt and suspenders.
    func move(_ p: CGPoint) {
        CGWarpMouseCursorPosition(p)
        if let e = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                           mouseCursorPosition: p, mouseButton: .left) {
            e.post(tap: .cghidEventTap)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

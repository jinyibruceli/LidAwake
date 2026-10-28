import Cocoa

// LidAwake: a menu bar switch that keeps your Mac running with the lid closed (pmset disablesleep).
// 菜单栏小开关：控制合上盖子后 Mac 是否继续运行。

let agentLabel = "com.lidawake.agent"
let agentPlist = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/LaunchAgents/\(agentLabel).plist")

let isChinese = Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
func t(_ en: String, _ zh: String) -> String { isChinese ? zh : en }

@discardableResult
func run(_ path: String, _ args: [String]) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: path)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    try? p.run()
    p.waitUntilExit()
    return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
}

let launchDomain = "gui/\(getuid())"

// Register a LaunchAgent so the icon starts at login and comes back if it quits or crashes.
func installAgent() {
    let exe = Bundle.main.executablePath ?? CommandLine.arguments[0]
    let plist: [String: Any] = [
        "Label": agentLabel,
        "ProgramArguments": [exe],
        "RunAtLoad": true,
        "KeepAlive": true,
        "ProcessType": "Interactive",
    ]
    try? FileManager.default.createDirectory(at: agentPlist.deletingLastPathComponent(), withIntermediateDirectories: true)
    (plist as NSDictionary).write(to: agentPlist, atomically: true)
    run("/bin/launchctl", ["bootout", "\(launchDomain)/\(agentLabel)"])
    run("/bin/launchctl", ["bootstrap", launchDomain, agentPlist.path])
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let toggleItem = NSMenuItem(title: "", action: #selector(toggle), keyEquivalent: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Opened by hand (Finder, Dock): hand over to launchd and let that copy own the icon.
        if ProcessInfo.processInfo.environment["XPC_SERVICE_NAME"] != agentLabel {
            installAgent()
            NSApp.terminate(nil)
            return
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        let menu = NSMenu()
        menu.delegate = self
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())
        let remove = NSMenuItem(title: t("Remove from Menu Bar", "从菜单栏移除"), action: #selector(uninstall), keyEquivalent: "")
        remove.target = self
        menu.addItem(remove)
        statusItem.menu = menu

        refresh()
    }

    func menuWillOpen(_ menu: NSMenu) { refresh() }

    private func sleepDisabled() -> Bool {
        let out = run("/usr/bin/pmset", ["-g"])
        for line in out.split(separator: "\n") where line.contains("SleepDisabled") {
            return line.trimmingCharacters(in: .whitespaces).hasSuffix("1")
        }
        return false
    }

    private func refresh() {
        let on = sleepDisabled()
        let symbol = on ? "cup.and.saucer.fill" : "moon.zzz"
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = on
            ? t("Keep running with lid closed: On", "合盖继续运行：开")
            : t("Keep running with lid closed: Off", "合盖继续运行：关")
        toggleItem.title = t("Keep Running with Lid Closed", "合盖继续运行")
        toggleItem.state = on ? .on : .off
    }

    @objc private func toggle() {
        let target = sleepDisabled() ? 0 : 1
        let script = "do shell script \"/usr/bin/pmset -a disablesleep \(target)\" with administrator privileges"
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
        refresh()
    }

    @objc private func uninstall() {
        try? FileManager.default.removeItem(at: agentPlist)
        // bootout kills this process, so it has to be the last step.
        run("/bin/launchctl", ["bootout", "\(launchDomain)/\(agentLabel)"])
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

import SwiftUI
import AppKit

// ╔══════════════════════════════════════════════════════════╗
// ║  LiquidWindow — 菜单栏窗口管理工具                        ║
// ╚══════════════════════════════════════════════════════════╝

@main
struct LiquidWindowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var hotKeyManager: HotKeyManager?
    private var animationMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        AccessibilityHelper.shared.requestAccessIfNeeded()
        hotKeyManager = HotKeyManager()
        hotKeyManager?.registerHotKeys()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "rectangle.split.2x1", accessibilityDescription: "LiquidWindow")
            image?.isTemplate = true
            button.image = image
        }

        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "LiquidWindow", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())

        // 动画开关
        animationMenuItem = NSMenuItem(title: "窗口动画", action: #selector(toggleAnimation), keyEquivalent: "")
        animationMenuItem.target = self
        animationMenuItem.state = WindowManager.shared.animationEnabled ? .on : .off
        menu.addItem(animationMenuItem)

        menu.addItem(NSMenuItem.separator())

        let accessibilityItem = NSMenuItem(title: "检查辅助功能权限", action: #selector(checkAccessibility), keyEquivalent: "")
        accessibilityItem.target = self
        menu.addItem(accessibilityItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出 LiquidWindow", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleAnimation() {
        WindowManager.shared.animationEnabled.toggle()
        animationMenuItem.state = WindowManager.shared.animationEnabled ? .on : .off
    }

    @objc private func checkAccessibility() {
        if AccessibilityHelper.shared.isAccessibilityEnabled() {
            let alert = NSAlert()
            alert.messageText = "辅助功能权限已开启"
            alert.informativeText = "LiquidWindow 可以正常控制窗口。"
            alert.alertStyle = .informational
            alert.runModal()
        } else {
            AccessibilityHelper.shared.requestAccessIfNeeded()
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

import Cocoa
import ApplicationServices

// ╔══════════════════════════════════════════════════════════╗
// ║  辅助功能权限管理                                         ║
// ║  请求权限前先重置，确保系统弹出新的授权对话框               ║
// ╚══════════════════════════════════════════════════════════╝

class AccessibilityHelper {
    static let shared = AccessibilityHelper()

    private init() {}

    // 检查辅助功能权限是否已开启
    func isAccessibilityEnabled() -> Bool {
        return AXIsProcessTrusted()
    }

    // 请求辅助功能权限（先重置再请求）
    func requestAccessIfNeeded() {
        if !isAccessibilityEnabled() {
            // 先重置当前 app 的辅助功能权限
            resetAccessibility()

            // 弹出系统权限请求对话框
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }

    // 重置辅助功能权限（通过 tccutil 命令）
    private func resetAccessibility() {
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        let task = Process()
        task.launchPath = "/usr/bin/tccutil"
        task.arguments = ["reset", "Accessibility", bundleId]
        try? task.run()
        task.waitUntilExit()
    }
}

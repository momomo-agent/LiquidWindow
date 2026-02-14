import AppKit
import CoreGraphics

class WindowManager {
    static let shared = WindowManager()

    var animationEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "animationEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "animationEnabled") }
    }

    private let widthRatios: [CGFloat] = [1.0/3.0, 1.0/2.0, 2.0/3.0, 1.0]
    private let heightRatios: [CGFloat] = [1.0/2.0, 1.0]

    enum HorizontalSide { case left, right, full }
    private var hSide: HorizontalSide = .full
    private var hStep: Int = 3

    enum VerticalSide { case top, bottom, full }
    private var vSide: VerticalSide = .full
    private var vStep: Int = 1

    private var lastWindowPID: pid_t = 0

    private init() {}

    // MARK: - 获取屏幕可用区域（AX 坐标系：y=0 在屏幕最顶部）
    private func getUsableFrame() -> CGRect? {
        guard let screen = NSScreen.main else { return nil }
        let full = screen.frame          // 整个屏幕
        let visible = screen.visibleFrame // 排除菜单栏和 Dock

        // 转成 AX 坐标系（y 从顶部算）
        let axY = full.height - visible.origin.y - visible.height
        return CGRect(x: visible.origin.x, y: axY, width: visible.width, height: visible.height)
    }

    // MARK: - 公开方法

    func moveLeft() {
        guard let (window, pid) = getFocusedWindow(),
              let area = getUsableFrame() else { return }
        checkAndResetState(pid: pid)

        switch hSide {
        case .left:
            if hStep > 0 { hStep -= 1 }
        case .right:
            if hStep < 3 { hStep += 1 }
            else { hSide = .left; hStep = 2 }
        case .full:
            hSide = .left; hStep = 2
        }
        applyLayout(window: window, area: area)
    }

    func moveRight() {
        guard let (window, pid) = getFocusedWindow(),
              let area = getUsableFrame() else { return }
        checkAndResetState(pid: pid)

        switch hSide {
        case .right:
            if hStep > 0 { hStep -= 1 }
        case .left:
            if hStep < 3 { hStep += 1 }
            else { hSide = .right; hStep = 2 }
        case .full:
            hSide = .right; hStep = 2
        }
        applyLayout(window: window, area: area)
    }

    func moveUp() {
        guard let (window, pid) = getFocusedWindow(),
              let area = getUsableFrame() else { return }
        checkAndResetState(pid: pid)

        switch vSide {
        case .top:
            if vStep > 0 { vStep -= 1 }
        case .bottom:
            if vStep < 1 { vStep += 1 }
            else { vSide = .top; vStep = 0 }
        case .full:
            vSide = .top; vStep = 0
        }
        applyLayout(window: window, area: area)
    }

    func moveDown() {
        guard let (window, pid) = getFocusedWindow(),
              let area = getUsableFrame() else { return }
        checkAndResetState(pid: pid)

        switch vSide {
        case .bottom:
            if vStep > 0 { vStep -= 1 }
        case .top:
            if vStep < 1 { vStep += 1 }
            else { vSide = .bottom; vStep = 0 }
        case .full:
            vSide = .bottom; vStep = 0
        }
        applyLayout(window: window, area: area)
    }

    // MARK: - 统一布局（直接用 AX 坐标系，不转换）

    private func applyLayout(window: AXUIElement, area: CGRect) {
        let wRatio = widthRatios[hStep]
        let hRatio = heightRatios[vStep]
        let w = area.width * wRatio
        let h = area.height * hRatio

        if hStep == 3 { hSide = .full }
        if vStep == 1 { vSide = .full }

        // X 坐标
        let x: CGFloat
        switch hSide {
        case .left, .full: x = area.origin.x
        case .right: x = area.origin.x + area.width - w
        }

        // Y 坐标（AX 坐标系：y 小 = 靠上，y 大 = 靠下）
        let y: CGFloat
        switch vSide {
        case .top, .full: y = area.origin.y
        case .bottom: y = area.origin.y + area.height - h
        }

        let target = CGRect(x: x, y: y, width: w, height: h)
        setWindowFrame(window, frame: target)
    }

    // MARK: - 窗口操作

    private func getFocusedWindow() -> (AXUIElement, pid_t)? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        var focusedWindow: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success,
              let window = focusedWindow else { return nil }
        return (window as! AXUIElement, pid)
    }

    private func getWindowFrame(_ window: AXUIElement) -> CGRect? {
        var posVal: CFTypeRef?, sizeVal: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posVal) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeVal) == .success else { return nil }
        var pos = CGPoint.zero, size = CGSize.zero
        AXValueGetValue(posVal as! AXValue, .cgPoint, &pos)
        AXValueGetValue(sizeVal as! AXValue, .cgSize, &size)
        return CGRect(origin: pos, size: size)
    }

    private func setWindowFrame(_ window: AXUIElement, frame: CGRect) {
        if animationEnabled, let current = getWindowFrame(window) {
            let steps = 8
            let interval: TimeInterval = 0.15 / Double(steps)
            for i in 1...steps {
                let t = easeOutCubic(Double(i) / Double(steps))
                let f = CGRect(
                    x: current.origin.x + (frame.origin.x - current.origin.x) * t,
                    y: current.origin.y + (frame.origin.y - current.origin.y) * t,
                    width: current.width + (frame.width - current.width) * t,
                    height: current.height + (frame.height - current.height) * t
                )
                applyFrame(window, frame: f)
                Thread.sleep(forTimeInterval: interval)
            }
        }
        applyFrame(window, frame: frame)
    }

    private func easeOutCubic(_ t: Double) -> CGFloat {
        let t1 = t - 1.0
        return CGFloat(t1 * t1 * t1 + 1.0)
    }

    private func applyFrame(_ window: AXUIElement, frame: CGRect) {
        var pos = frame.origin, size = frame.size
        if let v = AXValueCreate(.cgPoint, &pos) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, v)
        }
        if let v = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, v)
        }
    }

    private func checkAndResetState(pid: pid_t) {
        if pid != lastWindowPID {
            hSide = .full; hStep = 3
            vSide = .full; vStep = 1
            lastWindowPID = pid
        }
    }
}

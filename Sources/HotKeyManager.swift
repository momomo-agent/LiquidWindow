import Cocoa
import Carbon

// ╔══════════════════════════════════════════════════════════╗
// ║  全局快捷键管理器                                         ║
// ║  快捷键：Ctrl+⌘ + 方向键                                 ║
// ╚══════════════════════════════════════════════════════════╝

class HotKeyManager {
    private var hotKeyRefs: [EventHotKeyRef?] = []

    private enum HotKeyID: UInt32 {
        case moveLeft = 1
        case moveRight = 2
        case moveUp = 3
        case moveDown = 4
    }

    func registerHotKeys() {
        installEventHandler()

        let mods = UInt32(controlKey | cmdKey) // Ctrl+⌘

        registerHotKey(id: .moveLeft,  keyCode: 123, modifiers: mods) // ←
        registerHotKey(id: .moveRight, keyCode: 124, modifiers: mods) // →
        registerHotKey(id: .moveUp,    keyCode: 126, modifiers: mods) // ↑
        registerHotKey(id: .moveDown,  keyCode: 125, modifiers: mods) // ↓
    }

    private func registerHotKey(id: HotKeyID, keyCode: UInt32, modifiers: UInt32) {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x4C575F5F)
        hotKeyID.id = id.rawValue

        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        if status == noErr {
            hotKeyRefs.append(hotKeyRef)
        }
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { (_, event, _) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            guard GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID) == noErr else {
                return OSStatus(eventNotHandledErr)
            }

            DispatchQueue.main.async {
                switch hotKeyID.id {
                case HotKeyID.moveLeft.rawValue:  WindowManager.shared.moveLeft()
                case HotKeyID.moveRight.rawValue: WindowManager.shared.moveRight()
                case HotKeyID.moveUp.rawValue:    WindowManager.shared.moveUp()
                case HotKeyID.moveDown.rawValue:  WindowManager.shared.moveDown()
                default: break
                }
            }
            return noErr
        }, 1, &eventType, nil, nil)
    }
}

# LiquidWindow

macOS 菜单栏窗口管理工具，用快捷键快速调整窗口布局。

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| `⌘⇧←` | 窗口靠左，宽度循环：全屏 → 2/3 → 1/2 → 1/3 |
| `⌘⇧→` | 窗口靠右，宽度循环：全屏 → 2/3 → 1/2 → 1/3 |
| `⌘⇧↑` | 窗口靠上，高度切换：全屏 ↔ 1/2 |
| `⌘⇧↓` | 窗口靠下，高度切换：全屏 ↔ 1/2 |

## 构建

```bash
cd LiquidWindow
xcodegen generate
xcodebuild -project LiquidWindow.xcodeproj -scheme LiquidWindow -configuration Release build
```

## 要求

- macOS 14.0+
- 需要授予辅助功能权限（首次启动会提示）

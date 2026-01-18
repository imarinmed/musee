# MuseeGUI

**ExecutableTarget**: GUI application entry point for MuseeKit.

## STRUCTURE

10 Swift files - main GUI application module.

## WHERE TO LOOK

| Task | File | Notes |
|------|------|-------|
| Main entry | `main.swift` | App startup |
| Views | `MuseeGUI/` | SwiftUI view hierarchy |

## CONVENTIONS

- Uses MuseeUI components
- SwiftUI-based UI

## ANTI-PATTERNS (THIS MODULE)

- Do NOT mix AppKit/UIKit with SwiftUI
- Do NOT put business logic here - delegate to MuseeKit modules

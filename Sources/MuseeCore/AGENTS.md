# MuseeCore

**Target**: Foundation library - errors, platform abstractions, shared types.

## STRUCTURE

| File | Purpose |
|------|---------|
| `MuseeCore.swift` | Module marker |
| `MuseeError.swift` | Custom error enum |
| `PartialDate.swift` | Date handling |
| `PlatformImage.swift` | Platform image abstraction |
| `PlatformVisualEffect.swift` | Platform visual effect abstraction |
| `StableID.swift` | Stable identifier generation |

## WHERE TO LOOK

| Task | File | Notes |
|------|------|-------|
| Error handling | `MuseeError.swift` | Custom error enum |
| Platform abstractions | `PlatformImage.swift`, `PlatformVisualEffect.swift` | #if os(macOS) guards |

## CONVENTIONS

- No @MainActor assumptions
- All code platform-agnostic
- `private` by default, `public` when necessary

## ANTI-PATTERNS (THIS MODULE)

- **No UI code** - foundation only
- **No business logic** - only types and errors
- **No module-specific dependencies** - zero external deps

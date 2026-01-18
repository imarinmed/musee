# MuseeVision

**Target**: Vision framework beauty analysis with facial feature detection.

## STRUCTURE

4 files - Vision framework integration, face landmarks, beauty scoring.

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Beauty analysis | `BeautyAnalyzer.swift` | Vision framework calls |
| Face detection | `FaceDetectionResult.swift` | VNDetectFaceCaptureQualityRequest |
| Facial landmarks | `FacialLandmarks.swift` | Vision landmarks |

## CONVENTIONS

- Vision framework async handlers
- Coordinate conversions (image ↔ normalized)
- Face capture quality requests

## ANTI-PATTERNS (THIS MODULE)

- **Do NOT use @MainActor unless UI-bound**
- Do NOT use ImageIO - use Vision framework only
- Do NOT perform UI work in analyzer methods

# MuseeMetadata

**Target**: EXIF, face detection metadata extraction and processing.

## STRUCTURE

4 files - metadata parsing, face data extraction.

## WHERE TO LOOK

| Task | File | Notes |
|------|------|-------|
| EXIF parsing | `ImageMetadata.swift` | ImageIO framework |
| Face metadata | `FaceDetectionResult.swift` | Metadata for faces |

## CONVENTIONS

- CGImage property access
- ImageIO framework (not Vision)
- Metadata dictionary extraction

## ANTI-PATTERNS (THIS MODULE)

- **No Vision framework here - use ImageIO only**
- Do NOT perform face detection - only extract metadata
- Do NOT modify original image data

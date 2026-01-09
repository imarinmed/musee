# Security and Privacy

## Encryption

- **AES-GCM**: 256-bit encryption for backups
- **On-device Processing**: No data sent to external servers
- **Secure Keys**: Cryptographically secure key generation

## Data Protection

- **Access Controls**: Wing-level sharing permissions
- **GDPR Compliance**: Right to erasure and data portability
- **Anonymization**: Optional GPS data removal
- **Audit Trails**: Complete provenance logging

## Privacy Features

```swift
// Sanitize location data
func sanitizeMetadata(_ metadata: EXIFMetadata) -> SanitizedMetadata {
    return SanitizedMetadata(
        capturedAt: metadata.capturedAt,
        camera: metadata.camera,
        location: nil,  // Remove GPS
        exposure: metadata.exposure
    )
}
```
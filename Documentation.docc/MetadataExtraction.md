# Metadata Extraction and Provenance

Musee implements comprehensive metadata extraction and provenance tracking to ensure data authenticity, attribution, and historical integrity. The system processes multiple metadata standards and maintains cryptographic provenance for all claims and assets.

## Overview

Metadata extraction encompasses:

- **Standard Formats**: EXIF, IPTC, XMP metadata parsing
- **Content Authenticity**: C2PA verification for digital provenance
- **Claims System**: Attributed assertions with confidence and references
- **Provenance Chain**: Immutable audit trails for data lineage

## EXIF Metadata

### Exchangeable Image File Format

EXIF data contains camera and capture information embedded in image files.

#### Extracted Fields

| Field | Description | Usage |
|-------|-------------|-------|
| DateTimeOriginal | Capture timestamp | MediaAsset.capturedAt |
| Make/Model | Camera manufacturer | Device attribution |
| GPSLatitude/Longitude | Location data | Geographic tagging |
| Orientation | Image rotation | Display correction |
| ExposureTime | Shutter speed | Photography metadata |
| FNumber | Aperture | Photography metadata |
| ISOSpeedRatings | ISO sensitivity | Photography metadata |

#### EXIF Extraction

```swift
func extractEXIF(from data: Data) throws -> EXIFMetadata {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
        throw MetadataError.invalidImage
    }

    guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
        return EXIFMetadata()
    }

    return EXIFMetadata(
        capturedAt: extractDate(from: properties),
        camera: extractCameraInfo(from: properties),
        location: extractGPS(from: properties),
        exposure: extractExposure(from: properties)
    )
}
```

## IPTC Metadata

### International Press Telecommunications Council

IPTC provides standardized metadata for news and media content.

#### Supported Fields

- **Headline**: Article title or subject
- **Caption**: Image description
- **Keywords**: Subject tags
- **Credit**: Photographer attribution
- **Copyright**: Usage rights
- **Date Created**: Content creation date
- **City/Country**: Location information

#### IPTC Processing

```swift
struct IPTCMetadata {
    let headline: String?
    let caption: String?
    let keywords: [String]
    let credit: String?
    let copyright: String?
    let created: Date?
    let location: Location?
}
```

## XMP Metadata

### Extensible Metadata Platform

Adobe's XMP provides extensible metadata in XML format.

#### XMP Processing

```swift
func extractXMP(from data: Data) throws -> XMPMetadata {
    // Parse XMP packet from image data
    guard let xmpData = extractXMPPacket(from: data) else {
        return XMPMetadata()
    }

    let xml = try XMLDocument(data: xmpData)
    return XMPMetadata(
        creator: xml["dc:creator"],
        title: xml["dc:title"],
        description: xml["dc:description"],
        subject: xml["dc:subject"],
        rights: xml["dc:rights"]
    )
}
```

## C2PA Verification

### Content Authenticity Initiative

C2PA provides cryptographically verifiable provenance for digital content.

#### C2PA Components

- **Manifest**: Signed metadata about content creation and modifications
- **Assertions**: Claims about content provenance
- **Signatures**: Cryptographic verification of authenticity
- **Certificates**: Identity verification for creators

#### Verification Process

```swift
func verifyC2PA(from data: Data) throws -> C2PAStatus {
    let verifier = C2PAVerifier()

    do {
        let manifest = try verifier.verify(data: data)
        return C2PAStatus(
            verified: true,
            manifest: manifest,
            certificates: manifest.certificates
        )
    } catch {
        return C2PAStatus(
            verified: false,
            error: error.localizedDescription
        )
    }
}
```

## Claims System

### Biographical Assertions

Claims are attributed assertions about persons with provenance tracking.

#### Claim Structure

```swift
struct BiographicalClaim {
    let id: StableID
    let subject: StableID        // Person ID
    let property: ClaimProperty  // What is being claimed
    let value: ClaimValue        // The claim value
    let confidence: ConfidenceLevel
    let validAt: PartialDate     // When the claim is valid
    let references: [ClaimReference]  // Supporting evidence
}
```

#### Claim Properties

```swift
enum ClaimProperty: String, Codable {
    case height, weight, bust, waist, hips
    case hairStyle, hairColor
    case eross                    // Beauty score
    case relationship, similarity
    case note
}
```

#### Claim Values

```swift
enum ClaimValue: Hashable, Codable {
    case string(String)           // Text values
    case number(Double)           // Numeric measurements
    case person(StableID)         // Person references
    case media(StableID)          // Media references
}
```

### Confidence Levels

Claims include confidence indicators:

```swift
enum ConfidenceLevel {
    case high      // Verified with strong evidence
    case medium    // Reasonable confidence
    case low       // Preliminary or estimated
}
```

## Provenance Tracking

### Claim References

Every claim includes references for verification:

```swift
struct ClaimReference {
    enum ReferenceType: String, Codable {
        case webpage, publication, database, media, user, system
    }

    let type: ReferenceType
    let url: String?
    let title: String
    let retrievedAt: Date
}
```

### Provenance Chain

Claims maintain a chain of provenance:

```swift
struct ProvenanceChain {
    let claimID: StableID
    let createdBy: String          // System or user ID
    let createdAt: Date
    let basedOn: [StableID]        // Previous claims
    let evidence: [ClaimReference]
    let signature: Data?           // Optional cryptographic signature
}
```

## Metadata Pipeline

### Extraction Workflow

```swift
func extractMetadata(from asset: MediaAsset) async throws -> ProcessedMetadata {
    let data = try await loadAssetData(asset)

    // Parallel extraction
    async let exif = extractEXIF(from: data)
    async let iptc = extractIPTC(from: data)
    async let xmp = extractXMP(from: data)
    async let c2pa = verifyC2PA(from: data)

    // AI analysis
    async let vision = VisionProcessor.extractFeatures(from: data)
    async let tags = VisionProcessor.classifyImage(in: data)
    async let beauty = VisionProcessor.analyzeBeauty(from: try await vision)

    return ProcessedMetadata(
        exif: try await exif,
        iptc: try await iptc,
        xmp: try await xmp,
        c2pa: try await c2pa,
        visionFeatures: try await vision,
        autoTags: try await tags,
        beautyAnalysis: try await beauty
    )
}
```

### Claim Generation

AI results become verifiable claims:

```swift
func generateClaims(from metadata: ProcessedMetadata, for personID: StableID) -> [BiographicalClaim] {
    var claims = [BiographicalClaim]()

    // EROSS claim
    let erossScore = EROSCalculator.calculateEROSS(from: metadata.beautyAnalysis)
    claims.append(EROSSCalculator.createEROSSClaim(
        score: erossScore,
        for: personID,
        validAt: metadata.exif?.capturedAt ?? .now()
    ))

    // Auto-generated tags become claims
    for tag in metadata.autoTags {
        claims.append(BiographicalClaim(
            id: StableID(UUID().uuidString),
            subject: personID,
            property: .note,  // Or specific tag property
            value: .string(tag.value),
            confidence: .medium,
            validAt: .now(),
            references: [ClaimReference(
                type: .system,
                title: "AI classification",
                retrievedAt: Date()
            )]
        ))
    }

    return claims
}
```

## Storage and Indexing

### Immutable Storage

Metadata and claims are stored immutably:

```swift
func storeMetadata(_ metadata: ProcessedMetadata, claims: [BiographicalClaim]) async throws {
    // Store in CAS
    let metadataAddress = try await cas.store(metadata)
    let claimsAddress = try await cas.store(claims)

    // Update bundle manifest
    bundle.updateManifest(withMetadata: metadataAddress, claims: claimsAddress)
}
```

### Search Indexing

Claims enable rich search capabilities:

```swift
func indexClaims(_ claims: [BiographicalClaim]) async throws {
    for claim in claims {
        switch claim.property {
        case .eross:
            if case .number(let score) = claim.value {
                try await searchIndex.addEROSSScore(score, for: claim.subject)
            }
        case .height:
            if case .number(let height) = claim.value {
                try await searchIndex.addMeasurement(.height, value: height, for: claim.subject)
            }
        // ... other properties
        }
    }
}
```

## Verification and Validation

### Claim Validation

Claims can be validated against evidence:

```swift
func validateClaim(_ claim: BiographicalClaim) throws -> ValidationResult {
    // Check reference validity
    for reference in claim.references {
        try validateReference(reference)
    }

    // Verify confidence is appropriate
    let calculatedConfidence = assessConfidence(for: claim)
    guard calculatedConfidence >= claim.confidence else {
        throw ValidationError.insufficientConfidence
    }

    return ValidationResult.valid
}
```

### Conflict Resolution

Multiple claims may conflict:

```swift
func resolveConflicts(_ claims: [BiographicalClaim]) -> [BiographicalClaim] {
    // Group by property and time
    let grouped = Dictionary(grouping: claims) { ($0.property, $0.validAt) }

    return grouped.values.map { conflictingClaims in
        // Select highest confidence claim
        conflictingClaims.max(by: { $0.confidence < $1.confidence })!
    }
}
```

## Privacy and Security

### Data Protection

Metadata may contain sensitive information:

```swift
func sanitizeMetadata(_ metadata: EXIFMetadata) -> SanitizedMetadata {
    return SanitizedMetadata(
        capturedAt: metadata.capturedAt,  // Keep
        camera: metadata.camera,          // Keep
        location: nil,                    // Remove GPS for privacy
        exposure: metadata.exposure       // Keep technical data
    )
}
```

### Access Control

Claims have access levels:

```swift
enum AccessLevel {
    case public     // Visible to all
    case shared     // Visible to collaborators
    case private    // Visible only to owner
}
```

## Integration Examples

### Bundle Processing

```swift
let bundle = MuseeBundle(bundleURL: bundleURL)
let metadata = try await extractMetadata(from: bundle)

// Validate authenticity
guard metadata.c2pa.verified else {
    throw SecurityError.unverifiedContent
}

// Generate claims
let claims = generateClaims(from: metadata, for: personID)

// Store immutably
try await storeMetadata(metadata, claims: claims)
```

### Search with Metadata

```swift
let query = FacetedSearchQuery(
    personIds: [personID],
    erossRange: 80...100,
    dateRange: PartialDate.year(2023)...PartialDate.year(2024)
)

let results = try await searchEngine.search(query: query)
```

Metadata extraction and provenance tracking form the foundation of Musee's data integrity, enabling trustworthy beauty analysis and historical research while maintaining user privacy and content authenticity.
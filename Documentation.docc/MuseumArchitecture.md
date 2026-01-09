# Museum Architecture

Musee uses a sophisticated hierarchical architecture to organize and store media collections, combining traditional filesystem organization with content-addressed storage for immutability and efficiency.

## Overview

The museum architecture consists of three main organizational levels:

1. **Museum**: Top-level container (.museum directory)
2. **Wings**: Thematic categories within a museum
3. **Exhibits**: Individual collections of media bundles
4. **Bundles**: Self-contained media packages (.musee files)

## Museum Structure

### .museum Directory Layout

```
my-museum.museum/
├── museum.json          # Museum index and metadata
├── Wings/               # Wing directories
│   ├── fitness/         # Wing directory
│   │   ├── Exhibits/    # Exhibit bundles
│   │   │   ├── photo-001.musee
│   │   │   ├── video-002.musee
│   │   │   └── ...
│   │   └── metadata.json # Wing-specific metadata
│   └── singers/         # Another wing
│       └── Exhibits/
└── Objects/             # Content-addressed storage (optional)
    ├── ab/
    │   └── c123...      # SHA-256 prefixed files
    └── cd/
        └── e456...
```

### Museum Index (museum.json)

The museum index contains:

```json
{
  "formatVersion": "1.0",
  "createdAt": "2024-01-01T00:00:00Z",
  "wings": [
    {
      "id": "fitness",
      "name": "Fitness",
      "description": "Athletic and fitness media",
      "categories": ["bodybuilding", "running", "yoga"],
      "sharedWith": null
    }
  ]
}
```

## Wings

Wings are thematic categories that group related exhibits. Each wing has:

- **Unique ID**: Stable identifier (e.g., "fitness", "singers")
- **Display Name**: Human-readable title
- **Description**: Optional detailed description
- **Categories**: Custom sub-categories for organization
- **Sharing**: Optional list of users with access

### Wing Customization

Wings support flexible categorization:

```swift
let wing = MuseumIndex.Wing(
    id: StableID("fitness"),
    name: "Fitness Journey",
    description: "Evolution from amateur to professional athlete",
    categories: ["training", "competition", "recovery", "nutrition"],
    sharedWith: ["trainer@example.com"]
)
```

## Exhibits

Exhibits are collections of media bundles within a wing. Each exhibit is a .musee bundle containing:

- Media assets (images, videos, audio)
- Extracted metadata
- AI analysis results
- Biographical claims
- Provenance information

### Exhibit Organization

Exhibits are stored as individual .musee files in the wing's Exhibits/ directory. The filename typically reflects the content:

- `graduation-2020.musee`
- `wedding-photos.musee`
- `fitness-transformation.musee`

## Bundle Format (.musee)

Bundles are self-contained archives using a structured format.

### Bundle Structure

```
photo-bundle.musee/
├── manifest.json        # Bundle metadata and contents
└── Objects/             # Content-addressed storage
    ├── ab/
    │   └── c123def...   # SHA-256 prefixed media files
    └── metadata/
        └── claims.json  # Biographical claims
        └── vision.json  # AI analysis results
```

### Manifest Format

```json
{
  "formatVersion": "1.0",
  "createdAt": "2024-01-01T00:00:00Z",
  "assets": [
    {
      "id": "asset-001",
      "sha256": "abc123...",
      "kind": "image",
      "filename": "photo.jpg",
      "capturedAt": "2020-06-15",
      "contentAddress": "ab/c123..."
    }
  ],
  "claims": [
    {
      "id": "claim-001",
      "subject": "person-001",
      "property": "eross",
      "value": {"number": 85.5},
      "confidence": "medium",
      "validAt": "2020-06-15",
      "references": [
        {
          "type": "system",
          "title": "EROSS calculation",
          "retrievedAt": "2024-01-01T00:00:00Z"
        }
      ]
    }
  ]
}
```

## Content-Addressed Storage (CAS)

Musee uses SHA-256 based content-addressed storage for immutable asset storage.

### CAS Principles

- **Immutability**: Assets are never modified; new versions create new addresses
- **Deduplication**: Identical content shares the same address
- **Integrity**: SHA-256 ensures content hasn't been tampered with
- **Efficiency**: Large files stored once, referenced everywhere

### Storage Layout

Assets are stored in a two-level directory structure:

```
Objects/
├── a1/
│   ├── b2c3...  # File with SHA-256 starting with a1b2c3...
├── d4/
│   ├── e5f6...  # File with SHA-256 starting with d4e5f6...
└── metadata/
    ├── claims.json
    └── analysis.json
```

### Address Calculation

```swift
let data = try Data(contentsOf: assetURL)
let hash = SHA256.hash(data: data)
let address = hash.compactMap { String(format: "%02x", $0) }.joined()
let prefix = String(address.prefix(2))
let path = "Objects/\(prefix)/\(address)"
```

## Working with Museums

### Creating a Museum

```swift
let museumURL = URL(fileURLWithPath: "/path/to/my-museum.museum")
let wings = [
    MuseumIndex.Wing(id: StableID("fitness"), name: "Fitness"),
    MuseumIndex.Wing(id: StableID("career"), name: "Career")
]

let library = try MuseumLibrary.createNew(at: museumURL, wings: wings)
```

### Adding Exhibits

```swift
let bundle = MuseeBundle(bundleURL: bundleURL)
try library.install(bundle: bundle, intoWing: wings[0].id)
```

### Customizing Wings

```swift
var index = try library.readIndex()
let updatedWing = MuseumIndex.Wing(
    id: index.wings[0].id,
    name: index.wings[0].name,
    description: index.wings[0].description,
    categories: ["beginner", "intermediate", "advanced"],
    sharedWith: ["coach@example.com"]
)
index.wings[0] = updatedWing
try library.writeIndex(index)
```

## Advanced Concepts

### Wing Sharing

Wings can be shared with specific users for collaborative curation:

```swift
let sharedWing = MuseumIndex.Wing(
    id: StableID("collaboration"),
    name: "Team Project",
    sharedWith: ["alice@example.com", "bob@example.com"]
)
```

### Backup and Restore

Museums support encrypted backups:

```swift
let key = SymmetricKey(size: .bits256)
try library.backup(to: backupURL, key: key)

// Restore
try library.restore(from: backupURL, key: key, to: newMuseumURL)
```

### Cross-Platform Compatibility

The museum format is designed for cross-platform compatibility:
- Directory-based structure works on all major OS
- JSON metadata is universally readable
- SHA-256 addresses are standard across platforms
- Bundle format can be zipped for distribution
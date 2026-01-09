# Search and Discovery

Musee's search system provides powerful faceted discovery across media assets, persons, and beauty data, combining traditional text search with AI-enhanced filtering.

## Faceted Search Query

```swift
struct FacetedSearchQuery {
    let text: String?                    // Full-text search
    let personIds: Set<StableID>         // Filter by persons
    let tagValues: Set<String>           // Filter by tags
    let platform: Platform?              // Filter by source platform
    let mediaKind: MediaKind?            // Filter by media type
    let dateRange: ClosedRange<PartialDate>?  // Date filtering
    let rating: Int?                     // Star rating filter
    let erossRange: ClosedRange<Double>? // Beauty score filtering
}
```

## Search Engine Protocol

```swift
protocol SearchEngine {
    func search(query: FacetedSearchQuery) async throws -> [MediaAsset]
    func findSimilar(to assetId: StableID, limit: Int) async throws -> [MediaAsset]
    func index(asset: MediaAsset, tags: [Tag]) async throws
}
```

## AI-Enhanced Search

- **Auto-generated tags** from Vision classification
- **Beauty score filtering** with EROSS ranges
- **Similarity search** using perceptual hashing
- **Person recognition** and attribution
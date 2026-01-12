import Foundation
import MuseeCore
import MuseeDomain

/// Sorting and curation options for media collections.
public struct SortOptions: Codable, Sendable {
    public enum SortBy: String, Codable, Sendable {
        case capturedAt
        case erossScore
        case quality
        case fileSize
        case duration
        case relevance
        case alphabetical
        case custom
    }

    public enum SortOrder: String, Codable, Sendable {
        case ascending
        case descending
    }

    public let primarySort: SortBy
    public let primaryOrder: SortOrder
    public let secondarySort: SortBy?
    public let secondaryOrder: SortOrder?
    public let groupBy: SortBy?

    public init(
        primarySort: SortBy = .capturedAt,
        primaryOrder: SortOrder = .descending,
        secondarySort: SortBy? = nil,
        secondaryOrder: SortOrder? = .ascending,
        groupBy: SortBy? = nil
    ) {
        self.primarySort = primarySort
        self.primaryOrder = primaryOrder
        self.secondarySort = secondarySort
        self.secondaryOrder = secondaryOrder
        self.groupBy = groupBy
    }
}

/// Advanced curation rules for smart collections.
public struct CurationRule: Codable, Sendable {
    public enum RuleType: String, Codable, Sendable {
        case erossRange
        case qualityThreshold
        case dateRange
        case contentType
        case tagPresence
        case similarityCluster
        case duplicateDetection
        case customScript
    }

    public let type: RuleType
    public let parameters: [String: String]  // Flexible parameter storage
    public let isInclusive: Bool  // Include or exclude matching items

    public init(type: RuleType, parameters: [String: String] = [:], isInclusive: Bool = true) {
        self.type = type
        self.parameters = parameters
        self.isInclusive = isInclusive
    }
}

/// Represents a search query with faceted filters.
public struct FacetedSearchQuery: Sendable {
    public var text: String?
    public var personIds: Set<StableID> = []
    public var tagValues: Set<String> = []
    public var platform: Platform?
    public var mediaKind: MediaKind?
    public var dateRange: ClosedRange<PartialDate>?
    public var rating: Int?
    public var erossRange: ClosedRange<Double>?
    public var sortOptions: SortOptions?
    public var curationRules: [CurationRule]?

    public init(
        text: String? = nil,
        personIds: Set<StableID> = [],
        tagValues: Set<String> = [],
        platform: Platform? = nil,
        mediaKind: MediaKind? = nil,
        dateRange: ClosedRange<PartialDate>? = nil,
        rating: Int? = nil,
        erossRange: ClosedRange<Double>? = nil,
        sortOptions: SortOptions? = nil,
        curationRules: [CurationRule]? = nil
    ) {
        self.text = text
        self.personIds = personIds
        self.tagValues = tagValues
        self.platform = platform
        self.mediaKind = mediaKind
        self.dateRange = dateRange
        self.rating = rating
        self.erossRange = erossRange
        self.sortOptions = sortOptions
        self.curationRules = curationRules
    }
}

/// Protocol for search engines.
public protocol SearchEngine {
    /// Perform a faceted search.
    func search(query: FacetedSearchQuery) async throws -> [MediaAsset]

    /// Find similar assets (placeholder for ML-based similarity).
    func findSimilar(to assetId: StableID, limit: Int) async throws -> [MediaAsset]

    /// Index an asset for search.
    func index(asset: MediaAsset, tags: [Tag]) async throws

    /// Sort assets according to specified options.
    func sort(assets: [MediaAsset], options: SortOptions) async throws -> [MediaAsset]

    /// Apply curation rules to filter and organize assets.
    func curate(assets: [MediaAsset], rules: [CurationRule]) async throws -> [MediaAsset]

    /// Create or update a smart collection.
    func createSmartCollection(_ collection: MuseeSearch.SmartCollection) async throws

    /// Get assets matching a smart collection.
    func getSmartCollectionAssets(_ collectionId: StableID) async throws -> [MediaAsset]
}

/// Indexed in-memory search implementation with optimized data structures.
/// Provides O(1) lookups and efficient filtering for large datasets.
public actor InMemorySearchEngine: SearchEngine {
    private var indexedAssets: [StableID: (MediaAsset, Set<Tag>)] = [:]
    private var smartCollections: [StableID: SmartCollection] = [:]

    // Optimized indexes for fast queries
    private var assetsByTag: [String: Set<StableID>] = [:]
    private var assetsByKind: [String: Set<StableID>] = [:]
    private var assetsByDate: [String: Set<StableID>] = [:]  // Year-based grouping
    private var assetsByPerson: [StableID: Set<StableID>] = [:]  // Would need person associations

    // Reverse index for fast tag lookups
    private var tagsByAsset: [StableID: Set<String>] = [:]

    public func search(query: FacetedSearchQuery) async throws -> [MediaAsset] {
        // Start with all assets or use indexes to narrow down candidates
        var candidateIds: Set<StableID>

        // Use most restrictive filter first for optimization
        if !query.tagValues.isEmpty {
            // Find assets that have ANY of the required tags
            candidateIds = query.tagValues.compactMap { assetsByTag[$0] }.reduce(Set<StableID>()) { $0.union($1) }
            if candidateIds.isEmpty { return [] }
        } else if let mediaKind = query.mediaKind {
            candidateIds = assetsByKind[mediaKind.rawValue] ?? []
            if candidateIds.isEmpty { return [] }
        } else if let dateRange = query.dateRange {
            // Simple year-based filtering for now
            let startYear = dateRange.lowerBound.year ?? 1900
            let endYear = dateRange.upperBound.year ?? 2100
            candidateIds = (startYear...endYear).compactMap { assetsByDate["\($0)"] ?? [] }.reduce(Set<StableID>()) { $0.union($1) }
            if candidateIds.isEmpty { return [] }
        } else {
            candidateIds = Set(indexedAssets.keys)
        }

        // Filter candidates with remaining criteria
        var results: [MediaAsset] = []

        for assetId in candidateIds {
            guard let (asset, tags) = indexedAssets[assetId] else { continue }

            // Platform filter
            if let platform = query.platform {
                let matchesPlatform = asset.originalSourceURL.map { url in
                    url.host?.contains(platform.rawValue) ?? false
                } ?? false
                if !matchesPlatform { continue }
            }

            // Rating filter (simplified)
            if let rating = query.rating {
                if !tags.contains(where: { $0.value.contains("\(rating)") }) { continue }
            }

            // EROSS range (placeholder)
            if query.erossRange != nil {
                // Would need EROSS claims integration
                continue
            }

            // Person filter (placeholder)
            if !query.personIds.isEmpty {
                continue
            }

            // Text search
            if let text = query.text, !text.isEmpty {
                let searchableText = (asset.originalFilename ?? "") + tags.map(\.value).joined(separator: " ")
                if !searchableText.localizedCaseInsensitiveContains(text) { continue }
            }

            results.append(asset)
        }

        // Apply curation rules if specified
        if let rules = query.curationRules {
            results = try await curate(assets: results, rules: rules)
        }

        // Apply sorting if specified
        if let sortOptions = query.sortOptions {
            results = try await sort(assets: results, options: sortOptions)
        }

        return results
    }

    public func findSimilar(to assetId: StableID, limit: Int) async throws -> [MediaAsset] {
        guard indexedAssets[assetId] != nil else {
            return []
        }

        let others = indexedAssets.filter { $0.key != assetId }.values.map { $0.0 }
        return Array(others.shuffled().prefix(limit))
    }

    public func index(asset: MediaAsset, tags: [Tag]) async throws {
        let tagSet = Set(tags)
        indexedAssets[asset.id] = (asset, tagSet)
        tagsByAsset[asset.id] = Set(tags.map { $0.value })

        for tag in tags {
            assetsByTag[tag.value, default: []].insert(asset.id)
        }

        assetsByKind[asset.kind.rawValue, default: []].insert(asset.id)

        if let year = asset.capturedAt?.year {
            assetsByDate["\(year)", default: []].insert(asset.id)
        }
    }

    public func sort(assets: [MediaAsset], options: SortOptions) async throws -> [MediaAsset] {
        let sorted = assets.sorted { lhs, rhs in
            let comparison = compareAssets(lhs, rhs, by: options.primarySort)
            let result = options.primaryOrder == .ascending ? comparison : !comparison

            if result == false && options.secondarySort != nil {
                let secondaryComparison = compareAssets(lhs, rhs, by: options.secondarySort!)
                return options.secondaryOrder == .ascending ? secondaryComparison : !secondaryComparison
            }

            return result
        }

        // Group by if specified
        if let groupBy = options.groupBy {
            // Group assets by the specified criteria
            let grouped = Dictionary(grouping: sorted) { asset in
                groupKey(for: asset, by: groupBy)
            }

            // Sort groups and flatten
            let sortedGroups = grouped.sorted { lhs, rhs in
                compareGroups(lhs.key, rhs.key, by: options.primarySort)
            }

            return sortedGroups.flatMap { $0.value }
        }

        return sorted
    }

    public func curate(assets: [MediaAsset], rules: [CurationRule]) async throws -> [MediaAsset] {
        var filteredAssets = assets

        for rule in rules {
            filteredAssets = try await applyRule(rule, to: filteredAssets)
        }

        return filteredAssets
    }

    public func createSmartCollection(_ collection: MuseeSearch.SmartCollection) async throws {
        smartCollections[collection.id] = collection
    }

    public func getSmartCollectionAssets(_ collectionId: StableID) async throws -> [MediaAsset] {
        guard let collection = smartCollections[collectionId] else {
            return []
        }

        // Filter assets using the collection's predicate
        return indexedAssets.values.filter { asset, tags in
            collection.contains(asset: asset, tags: tags)
        }.map { $0.0 }
    }

    // Helper methods
    private func compareAssets(_ lhs: MediaAsset, _ rhs: MediaAsset, by sortBy: SortOptions.SortBy) -> Bool {
        switch sortBy {
        case .capturedAt:
            let lhsDate = lhs.capturedAt ?? PartialDate(year: 1900, month: nil, day: nil, precision: .year)
            let rhsDate = rhs.capturedAt ?? PartialDate(year: 1900, month: nil, day: nil, precision: .year)
            return lhsDate < rhsDate
        case .erossScore:
            // Would need EROSS claims lookup
            return lhs.id.rawValue < rhs.id.rawValue  // Placeholder
        case .quality:
            // Would need quality metrics
            return lhs.id.rawValue < rhs.id.rawValue  // Placeholder
        case .fileSize:
            return false  // Would need file size info
        case .duration:
            return false  // Would need duration for videos/audio
        case .relevance:
            return lhs.id.rawValue < rhs.id.rawValue  // Placeholder
        case .alphabetical:
            return (lhs.originalFilename ?? "") < (rhs.originalFilename ?? "")
        case .custom:
            return lhs.id.rawValue < rhs.id.rawValue  // Placeholder
        }
    }

    private func groupKey(for asset: MediaAsset, by sortBy: SortOptions.SortBy) -> String {
        switch sortBy {
        case .capturedAt:
            return asset.capturedAt?.year.map { "\($0)" } ?? "unknown"
        case .erossScore:
            return "eross"  // Would group by score ranges
        default:
            return "default"
        }
    }

    private func compareGroups(_ lhs: String, _ rhs: String, by sortBy: SortOptions.SortBy) -> Bool {
        // Simple string comparison for now
        return lhs < rhs
    }

    private func applyRule(_ rule: CurationRule, to assets: [MediaAsset]) async throws -> [MediaAsset] {
        switch rule.type {
        case .erossRange:
            // Placeholder for EROSS range filtering
            return assets
        case .qualityThreshold:
            // Placeholder for quality filtering
            return assets
        case .dateRange:
            // Placeholder for date filtering
            return assets
        case .contentType:
            // Filter by media kind
            let allowedTypes = rule.parameters["types"]?.split(separator: ",").map { MediaKind(rawValue: String($0)) } ?? []
            return assets.filter { allowedTypes.contains($0.kind) }
        case .tagPresence:
            // Filter by tag presence
            let requiredTags = rule.parameters["tags"]?.split(separator: ",").map { String($0) } ?? []
            return assets.filter { asset in
                if let (_, tags) = indexedAssets[asset.id] {
                    let tagValues = tags.map { $0.value }
                    return requiredTags.allSatisfy { requiredTag in
                        tagValues.contains(where: { $0.contains(requiredTag) })
                    }
                }
                return false
            }
        case .similarityCluster:
            // Placeholder for similarity clustering
            return assets
        case .duplicateDetection:
            // Placeholder for duplicate detection
            return assets
        case .customScript:
            // Placeholder for custom scripting
            return assets
        }
    }
}

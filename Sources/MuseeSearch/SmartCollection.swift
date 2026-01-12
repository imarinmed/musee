import Foundation
import MuseeCore
import MuseeDomain

/// Protocol for collection predicates.
public protocol CollectionPredicate: Sendable {
    /// Evaluate if an asset matches this predicate.
    func matches(asset: MediaAsset, tags: Set<Tag>) -> Bool
}

/// Smart collection with rule-based membership.
public struct SmartCollection: Sendable {
    public let id: StableID
    public let name: String
    public let predicate: CollectionPredicate

    public init(id: StableID, name: String, predicate: CollectionPredicate) {
        self.id = id
        self.name = name
        self.predicate = predicate
    }

    public func contains(asset: MediaAsset, tags: Set<Tag>) -> Bool {
        predicate.matches(asset: asset, tags: tags)
    }
}

/// Predicate that matches assets with specific tags.
public struct TagPredicate: CollectionPredicate {
    public let requiredTags: Set<Tag>

    public init(requiredTags: Set<Tag>) {
        self.requiredTags = requiredTags
    }

    public func matches(asset: MediaAsset, tags: Set<Tag>) -> Bool {
        requiredTags.isSubset(of: tags)
    }
}

/// Predicate that matches assets within a date range.
public struct DateRangePredicate: CollectionPredicate {
    public let dateRange: ClosedRange<PartialDate>

    public init(dateRange: ClosedRange<PartialDate>) {
        self.dateRange = dateRange
    }

    public func matches(asset: MediaAsset, tags: Set<Tag>) -> Bool {
        guard let capturedAt = asset.capturedAt else {
            return false
        }
        return dateRange.contains(capturedAt)
    }
}

/// Predicate that matches assets of specific media kinds.
public struct MediaKindPredicate: CollectionPredicate {
    public let kinds: Set<MediaKind>

    public init(kinds: Set<MediaKind>) {
        self.kinds = kinds
    }

    public func matches(asset: MediaAsset, tags: Set<Tag>) -> Bool {
        kinds.contains(asset.kind)
    }
}

/// Composite predicate with AND/OR logic.
public struct CompositePredicate: CollectionPredicate {
    public enum Logic: Sendable {
        case and
        case or
    }

    public let predicates: [CollectionPredicate]
    public let logic: Logic

    public init(predicates: [CollectionPredicate], logic: Logic = .and) {
        self.predicates = predicates
        self.logic = logic
    }

    public func matches(asset: MediaAsset, tags: Set<Tag>) -> Bool {
        switch logic {
        case .and:
            return predicates.allSatisfy { $0.matches(asset: asset, tags: tags) }
        case .or:
            return predicates.contains { $0.matches(asset: asset, tags: tags) }
        }
    }
}

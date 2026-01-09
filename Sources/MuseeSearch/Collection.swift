import Foundation
import MuseeCore
import MuseeDomain

/// Represents a manual or smart collection of assets.
public struct Collection {
    public let id: StableID
    public let name: String
    public let description: String?
    public let kind: Kind

    public enum Kind {
        case manual(assetIds: Set<StableID>)
        case smart(predicate: CollectionPredicate)
    }

    public init(id: StableID, name: String, description: String? = nil, kind: Kind) {
        self.id = id
        self.name = name
        self.description = description
        self.kind = kind
    }

    public func contains(asset: MediaAsset, tags: Set<Tag>) -> Bool {
        switch kind {
        case .manual(let assetIds):
            return assetIds.contains(asset.id)
        case .smart(let predicate):
            return predicate.matches(asset: asset, tags: tags)
        }
    }
}

/// Collection hierarchy support.
public struct CollectionHierarchy {
    public let parentId: StableID?
    public let children: [StableID]

    public init(parentId: StableID?, children: [StableID]) {
        self.parentId = parentId
        self.children = children
    }
}